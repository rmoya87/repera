import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
import {slugFromName,uniqueSlug,visiblePlans,priceLabel} from '../core/business-profile.js';
import {renderPlanOptions,renderOrganizationFields,renderOrganizationCreateForm,renderPlanAdministration} from './business-onboarding.js';
import {renderServicesPanel} from './connected-services.js';
import {renderProfessionalPlanning} from './connected-planning.js';
import {navIcon} from './nav-icons.js';
import {renderPlatformAdmin,paymentCSV} from './platform-admin.js';
import {renderBusinessHome,renderClient360,renderClasses360} from './management-360.js';
import {renderTrainerPassPanel,trainerSeatInfo} from './trainer-pass-panel.js';
import {handleEditorClick,handleEditorSearch,readPrescription,validatePrescription,canonicalPrescription,emptyPrescription,editorMarkup} from './workout-editor.js';
const app=document.querySelector('#app');
const auth=new ReperaAuthAPI({baseUrl:SUPABASE_URL,publishableKey:SUPABASE_PUBLISHABLE_KEY});
const escapeHTML=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let adminTab='home',adminSelectedOrg='',delegation=null,adminDirectory=[],adminAthletes=[],adminSettings={},
adminAccount={},adminEditPlan='',adminFinances={payments:[],intents:[]},adminPending=[],adminHistory=[],
adminSelectedAthlete='',adminCenterDetail=null,adminAthleteDetail=null,adminAthleteWorkouts=[],
adminActivityMonth='',adminActivityDays=[],adminActivityDay='',adminActivityWorkouts=null,adminActivityLoading=false,
adminAthleteSection='exercises',adminCenterSection='data',
adminNavCollapsed=(()=>{try{return localStorage.getItem('repera.admin.nav.collapsed')==='1';}catch{return false;}})();
let adminFilter={search:'',kind:'all',athleteSearch:'',status:'all',org:'all',paymentStatus:'all',paymentScope:'b2b',dateFrom:'',dateTo:''};
let user=null,platformRole=null,platformOrgs=[],organizations=[],memberships=[],invitations=[],clients=[],occurrences=[],passes=[],offers=[],attendance=[],bookings=[],professionalSessions=[],templates=[],selectedOrg=null,trialRows=[],classDetails=[],groups=[],groupMembers=[],notices=[],enrollmentRequests=[],sharedHistory=[],selectedClientId=null,clientSection='training',trainerActivityMonth='',trainerActivityDay='',clientEditorOpen=false,selectedClassId=null,selectedGroupId=null,classMode='calendar',calendarMonth='',classEditorId=null,planningClientId=null,planningSelectedDay='',activeTab='overview',selectedTemplateId=null,editingSessionId=null,legalProfile=null,planCatalog=[],view='login',busy=false,error='',notice='',businessDialog='',dialogDay='',settingsSection='profile',bulkMode='custom';
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador personal',sports_center:'Gimnasio'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
const message=()=>`${error?`<p class="connected-error" role="alert">${escapeHTML(error)}</p>`:''}${notice?`<p class="connected-notice" role="status">${escapeHTML(notice)}</p>`:''}`;
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname+location.search;
const inviteId=new URLSearchParams(location.search).get('invitation')||'';
const invitationLink=/^[0-9a-f-]{36}$/i.test(inviteId);

const trainerActive=()=>organizations.find(o=>o.id===selectedOrg)?.kind==='personal_trainer';
function restoreWorkspaceRoute(){
 const p=new URLSearchParams(location.search),section=p.get('seccion'),client=p.get('cliente'),org=p.get('espacio');
 if(org&&/^[0-9a-f-]{36}$/i.test(org))selectedOrg=org;
 if(['overview','clients','planning','services','bonos','billing','analytics','team','settings'].includes(section||''))activeTab=section;
 if(client&&/^[0-9a-f-]{36}$/i.test(client)){selectedClientId=client;planningClientId=client;activeTab='clients';}
 else if(section==='clients'){selectedClientId=null;planningClientId=null;editingSessionId=null;selectedTemplateId=null;}
}
function setWorkspaceRoute(replace=false){
 if(!user||!selectedOrg)return;
 const uri=new URL(location.href);
 uri.searchParams.set('espacio',selectedOrg);
 uri.searchParams.set('seccion',activeTab);
 if(activeTab==='clients'&&selectedClientId)uri.searchParams.set('cliente',selectedClientId);
 else uri.searchParams.delete('cliente');
 history[replace?'replaceState':'pushState'](null,'',uri.pathname+uri.search+uri.hash);
}
function trainerDialogMarkup({manager,members}){
 if(!trainerActive()||!businessDialog)return '';
 const iso=/^\d{4}-\d{2}-\d{2}$/.test(dialogDay)?dialogDay:new Date().toLocaleDateString('sv-SE');
 let title='',inner='';
 if(businessDialog==='bulk'){
  title='Crear planificación';
  const linked=clients.filter(c=>c.user_id&&c.status==='active');
  const today=new Date().toLocaleDateString('sv-SE');
  const start=trainerActivityDay&&trainerActivityDay>=today?trainerActivityDay:today;
  const tabs=`<nav class="trainer-bulk-modes">
    <button type="button" data-action="bulk-mode" data-mode="custom" aria-current="${bulkMode==='custom'?'page':'false'}">Crear nuevo entrenamiento</button>
    <button type="button" data-action="bulk-mode" data-mode="template" aria-current="${bulkMode==='template'?'page':'false'}">Usar plantilla guardada</button></nav>`;
  const custom=`<form data-connected="bulk-custom" class="business-bulk-form trainer-bulk-custom">
    <p class="connected-hint">1. Diseña el entrenamiento. 2. Elige a quién y cuándo asignarlo. 3. Publica.
    No necesitas un Excel ni guardar una plantilla. Máximo 120 asignaciones por operación.</p>
    <label class="connected-field">Nombre del entrenamiento<input name="title" minlength="2" maxlength="120" required placeholder="Fuerza + WOD"></label>
    ${editorMarkup(emptyPrescription())}
    <label class="connected-field">Indicaciones para el atleta<textarea name="instructions" maxlength="10000" rows="3" placeholder="Objetivos y recomendaciones"></textarea></label>
    <fieldset class="business-bulk-step"><legend>Destinatarios</legend><div class="business-bulk-athletes">
    ${linked.map(c=>`<label class="business-bulk-athlete"><input name="clients" type="checkbox" value="${escapeHTML(c.id)}" ${c.id===selectedClientId?'checked':''}><span class="business-avatar">${escapeHTML(c.name.slice(0,1))}</span><strong>${escapeHTML(c.name)}</strong></label>`).join('')||'No hay atletas vinculados'}</div></fieldset>
    <fieldset class="business-bulk-step"><legend>Fechas y días</legend>
    <div class="business-bulk-dates">
    <label class="connected-field">Desde<input name="start" type="date" min="${today}" value="${start}" required></label>
    <label class="connected-field">Hasta<input name="end" type="date" min="${today}" value="${start}" required></label></div>
    <div class="business-bulk-weekdays">${['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'].map((name,i)=>`<label><input type="checkbox" name="weekdays" value="${i+1}" checked><span>${name.slice(0,2)}</span></label>`).join('')}</div></fieldset>
    <p class="connected-hint" role="status" data-custom-preview>Selecciona destinatarios y bloques.</p>
    <button type="submit" class="connected-primary" ${!linked.length?'disabled':''}>Publicar planificación</button></form>`;
  inner=tabs+(bulkMode==='custom'?custom:renderProfessionalPlanning({
   orgId:selectedOrg,role:manager?'owner':(memberships.find(m=>m.organization_id===selectedOrg&&m.user_id===user?.id&&m.status==='active')?.role||'athlete'),
   sessions:professionalSessions,templates,clients,memberships,busy,escapeHTML,
   clientId:selectedClientId,bulkOnly:true}));
 }else if(businessDialog==='trainer-session'){
  title='Registrar sesión presencial';
  const c=clients.find(x=>x.id===selectedClientId);
  const eligible=passes.filter(p=>p.client_id===selectedClientId&&p.kind==='appointment'&&
   p.status==='active'&&(new Date(p.valid_until)>new Date()&&p.remaining_credits>0||bookings.some(b=>b.pass_id===p.id&&b.status==='booked')));
  inner=c?`<p class="connected-hint">La sesión se registra en el momento de realizarla, incluso si no preparaste un entrenamiento. Se descontará un crédito del bono elegido.</p>
  <form class="business-form" data-connected="trainer-attendance"><input name="client" type="hidden" value="${escapeHTML(c.id)}">
  <label class="connected-field">Bono de ${escapeHTML(c.name)}<select name="pass" required>${eligible.map(p=>`<option value="${escapeHTML(p.id)}">${p.remaining_credits} de ${p.total_credits} sesiones restantes · hasta ${escapeHTML(new Date(p.valid_until).toLocaleDateString('es-ES'))}</option>`).join('')}</select></label>
  <label class="connected-field">Cita de agenda (opcional)<select name="occurrence"><option value="">Sin cita previa</option>${occurrences.filter(o=>o.kind==='appointment'&&o.status==='active').map(o=>`<option value="${escapeHTML(o.id)}">${escapeHTML(o.title)} · ${escapeHTML(new Date(o.starts_at).toLocaleDateString('es-ES'))}</option>`).join('')}</select></label>
  <label class="connected-field">Notas<textarea name="note" rows="2" maxlength="1000"></textarea></label>
  <button class="connected-primary" type="submit" ${eligible.length?'':'disabled'}>Confirmar sesión realizada</button>
  ${eligible.length?'':'<p>No hay saldo disponible. Asigna un bono desde Bonos y tarifas.</p>'}</form>`:'<p>Cliente no encontrado.</p>';
 }else if(businessDialog==='new-appointment'){
  title='Nueva cita o grupo';
  inner=`<form data-connected="service-occurrence" class="business-form">
  <label class="connected-field">Tipo<select name="kind"><option value="appointment">Cita individual</option><option value="class">Grupo</option></select></label>
  <label class="connected-field">Nombre<input name="title" value="Sesión personal" minlength="2" maxlength="120" required></label>
  <label class="connected-field">Inicio<input name="start" type="datetime-local" value="${iso}T10:00" required></label>
  <label class="connected-field">Fin<input name="end" type="datetime-local" value="${iso}T11:00" required></label>
  <label class="connected-field">Aforo: 1 para una cita individual<input name="capacity" type="number" min="1" max="200" value="1" required></label>
  <label class="connected-field">Entrenador<select name="coach">${members.map(m=>`<option value="${escapeHTML(m.user_id)}">${escapeHTML(m.label)}</option>`).join('')}</select></label>
  <input type="hidden" name="repeat" value="none"><input type="hidden" name="repeatCount" value="1">
  <p class="connected-hint">Después podrás inscribir al deportista desde el detalle utilizando un bono válido.</p>
  <button type="submit" class="connected-primary" ${!manager||!members.length?'disabled':''}>Crear en agenda</button></form>`;
 }else if(businessDialog==='occurrence'){
  title='Detalle de cita o grupo';
  inner=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches:members,selected:selectedClassId,classEditor:classEditorId===selectedClassId,manager});
 }else if(businessDialog==='group'){
  title='Datos del grupo';
  inner=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches:members,selectedGroup:selectedGroupId,manager});
 }
 return `<div class="business-overlay"><section class="business-dialog" role="dialog" aria-modal="true" aria-label="${title}"><div class="business-dialog-header"><h2>${title}</h2><button type="button" class="icon-button" data-action="close-business-dialog" aria-label="Cerrar">×</button></div><div class="business-dialog-scroll">${inner}</div></section></div>`;
}


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
 const seat=trainerSeatInfo({clients,trials:trialRows,plans:planCatalog});
 const visibleOrganizations=delegation?organizations.filter(x=>x.id===delegation.org_id):organizations;
 const tabs=org?[['overview','Inicio','dashboard'],['clients','Clientes','clients'],...(trainer?[]:[['planning','Entrenamientos','planning'],['services','Clases y reservas','calendar']]),['bonos','Bonos y tarifas','products'],['billing','Facturación','billing'],['analytics','Analíticas','analytics'],...(trainer?[]:[['team','Equipo y espacios','team']]),['settings','Configuración','settings'],...(platformRole==='platform_admin'&&!delegation?[['platform','Administración Repera','admin']]:[])]:[['overview','Inicio','dashboard'],...(platformRole==='platform_admin'?[['platform','Administración Repera','admin']]:[])];
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
 attach('overview',renderBusinessHome({org,clients,occurrences,bookings,sessions:professionalSessions,templates,requests:enrollmentRequests,manager,calendarMonth}));
 attach('clients',renderClient360({clients,selected:selectedClientId,passes,bookings,occurrences,sessions:professionalSessions,notices,sharedHistory,attendance,trainerActivityMonth,trainerActivityDay,manager,trainer,seat,role:own.get(selectedOrg),clientSection})+(trainer&&selectedClientId&&!clients.find(c=>c.id===selectedClientId)?.account_deleted_at&&clientSection==='training'&&clientEditorOpen?renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients:clients.filter(c=>!c.account_deleted_at),memberships,busy,escapeHTML,templateId:selectedTemplateId,sessionId:editingSessionId,clientId:selectedClientId,embedded:true,preferredDate:planningSelectedDay}):''));
 const members=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'&&['owner','admin','coach'].includes(m.role)).map(m=>({user_id:m.user_id,label:m.user_id===user.id?'Mi cuenta':'Profesional '+m.user_id.slice(0,8)}));
 // A pre-registration center has no real owner/staff yet. The real actor can operate
 // its workspace as Repera support; we never label this account as the future trainer.
 if(delegation&&!members.some(m=>m.user_id===user.id))members.unshift({user_id:user.id,label:'Administrador Repera · soporte'});
 if(!trainer)attach('services',renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,selectedGroup:selectedGroupId,coaches:members,selected:selectedClassId,classEditor:classEditorId===selectedClassId,listMode:classMode,calendarMonth,manager}));
 if(trainer){attach('bonos',renderTrainerPassPanel({clients,passes,offers,attendance,bookings,occurrences,seat,manager,busy}));}
 else attach('bonos',`<section class="connected-card"><h2>Bonos y tarifas</h2>
 <p>Define las tarifas que verán los deportistas vinculados en la app. Publicar un bono no equivale a un cobro: la compra se activará cuando la pasarela esté configurada y confirme el pago.</p>
 <h3>Tarifas publicadas</h3>
 ${offers.length?offers.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)} · ${o.kind==='class'?'Clases':'Entrenamiento personal'}</strong>
 <small>${Number(o.credits)} sesiones · ${Number(o.validity_days)} días · ${(Number(o.price_cents)/100).toLocaleString('es-ES',{style:'currency',currency:'EUR'})} · ${o.is_active?'Visible':'Desactivado'}</small></div>
 ${manager?`<button type="button" class="connected-secondary" data-action="toggle-pass-offer" data-id="${escapeHTML(o.id)}" data-active="${o.is_active?'true':'false'}">${o.is_active?'Desactivar':'Activar'}</button>`:''}
 </article>`).join(''):'<p>No hay tarifas configuradas.</p>'}
 ${manager?`<h3>Crear bono</h3><form data-connected="create-pass-offer" class="connected-plan-editor">
 <label class="connected-field">Nombre del bono<input name="name" type="text" minlength="2" maxlength="120" placeholder="Bono 10 entrenamientos" required></label>
 <div class="connected-form-grid">
 <label class="connected-field">Tipo<select name="kind"><option value="appointment">Entrenador personal</option><option value="class">Clases</option></select></label>
 <label class="connected-field">Número de sesiones<input name="credits" type="number" min="1" max="1000" value="10" required></label>
 <label class="connected-field">Validez (días)<input name="validityDays" type="number" min="1" max="730" value="90" required></label>
 <label class="connected-field">Precio (€)<input name="price" type="number" min="0" max="100000" step="0.01" required></label></div>
 <button class="connected-primary" type="submit" ${busy?'disabled':''}>Publicar bono</button></form>`:''}
 <h3>Bonos asignados</h3>
 ${passes.map(p=>`<article class="connected-org"><strong>${escapeHTML(clients.find(c=>c.id===p.client_id)?.name||'Cliente')} · ${p.kind==='class'?'Clase':'Cita'}</strong><small>${p.remaining_credits} de ${p.total_credits} disponibles</small></article>`).join('')||'<p>No hay bonos asignados.</p>'}
 <p class="connected-hint">Los bonos de cortesía no generan ingresos. No se simulan cobros reales.</p>
 </section>`);
 attach('billing',`<section class="connected-card"><h2>Facturación</h2><p>La pasarela de pago y la facturación legal todavía no están habilitadas. No se muestran cobros simulados como reales.</p></section>`);
 attach('platform',`<section class="connected-card"><h2>Administración Repera</h2><p>Resumen de organizaciones de la plataforma. No permite acceder al historial privado de los deportistas ni suplantar cuentas.</p><div class="table-scroll"><table><thead><tr><th>Organización</th><th>Tipo</th><th>Clientes</th><th>Prueba finaliza</th></tr></thead><tbody>${platformOrgs.map(o=>`<tr><td>${escapeHTML(o.name)}</td><td>${escapeHTML(o.kind)}</td><td>${Number(o.client_count||0)}</td><td>${escapeHTML(o.trial_ends_at?.slice(0,10)||'—')}</td></tr>`).join('')||'<tr><td colspan="4">No hay organizaciones</td></tr>'}</tbody></table></div></section>${platformRole==='platform_admin'?renderPlanAdministration(planCatalog):''}`);
 attach('analytics',`<section class="connected-card"><h2>Analíticas del negocio</h2><div class="business-stats"><div class="business-stat"><span>Clientes</span><strong>${clients.length}</strong></div><div class="business-stat"><span>Reservas activas</span><strong>${bookings.filter(b=>b.status==='booked').length}</strong></div><div class="business-stat"><span>Sesiones programadas</span><strong>${occurrences.filter(o=>o.status==='active').length}</strong></div></div><p>Las métricas deportivas personales solo estarán disponibles con consentimiento y sincronización del atleta.</p></section>`);
 const settings=document.createElement('section');settings.className='connected-card connected-settings';settings.dataset.workspaceSection='settings';
 settings.innerHTML=`${trainer?`<nav class="business-settings-navigation" aria-label="Secciones de configuración"><button data-settings-section="profile" type="button" aria-current="${settingsSection==='profile'?'page':'false'}">Datos del profesional</button><button data-settings-section="plan" type="button" aria-current="${settingsSection==='plan'?'page':'false'}">Plan y suscripción</button></nav>`:''}<div data-settings-panel="profile"><span class="connected-tag">DATOS DEL ${trainer?'PROFESIONAL':'NEGOCIO'}</span><h2>Configuración de ${escapeHTML(org.name)}</h2><p>Completa tu perfil. Los datos fiscales quedan restringidos a propietarios y administradores.</p><form data-connected="settings" class="business-onboarding-form">${renderOrganizationFields({kind,values:org,legal:legalProfile||{}}).replace('<select name="kind">','<select name="kind" disabled>')}<label class="connected-field">Zona horaria<input name="timezone" value="${escapeHTML(org.timezone||'Europe/Madrid')}" maxlength="80"></label>${manager?'<button class="connected-primary business-form-submit" type="submit">Guardar datos del negocio</button>':''}</form></div>`;
 root.append(settings);
 attach('settings',`<div data-settings-panel="plan">${renderSubscriptions(org)}</div>`);
 // Entrenador y gimnasio disponen de permisos diferentes.
 if(trainer)root.querySelector('[data-workspace-section="team"]')?.remove();
 const trial=trialStatus();
 if(!trial.active&&!delegation&&activeTab!=='settings'){
  const notice=document.createElement('div');notice.className='connected-error';notice.innerHTML='<strong>Prueba finalizada.</strong> Para seguir administrando el negocio, elige un plan en Configuración. Los pagos todavía no están disponibles.';
  nav.insertAdjacentElement('afterend',notice);
 }
 root.querySelectorAll('[data-workspace-section]').forEach(el=>{el.style.display=el.dataset.workspaceSection===activeTab?'':'none';});
 if(trainer){root.querySelectorAll('[data-settings-panel]').forEach(el=>el.style.display=el.dataset.settingsPanel===settingsSection?'':'none');root.insertAdjacentHTML('beforeend',trainerDialogMarkup({manager,members}));if(businessDialog==='bulk'){const bulk=root.querySelector('form[data-connected="bulk-training"]');if(bulk)refreshBulkPlanPreview(bulk);}}
}function render(){
 if(user&&platformRole==='platform_admin'&&!delegation&&view!=='password'){
  app.innerHTML=renderPlatformAdmin({tab:adminTab,orgs:adminDirectory,athletes:adminAthletes,finance:adminFinances,
   pending:adminPending,history:adminHistory,plans:planCatalog,selectedOrg:adminSelectedOrg,
   selectedAthlete:adminSelectedAthlete,centerDetail:adminCenterDetail,
   athleteData:adminAthleteDetail,athleteWorkouts:adminAthleteWorkouts,collapsed:adminNavCollapsed,
   activityMonth:adminActivityMonth,activityDays:adminActivityDays,
   activityDay:adminActivityDay,activityDayWorkouts:adminActivityWorkouts,activityLoading:adminActivityLoading,
   athleteSection:adminAthleteSection,centerSection:adminCenterSection,
   settings:adminSettings,account:adminAccount,editingPlan:adminEditPlan,
   filter:adminFilter,busy,error,notice,email:user.email||''});
  return;
 }
 const common=platformRole==='platform_admin'&&delegation?'':`<header class="connected-header"><div class="brand"><span class="brand-symbol">R</span><span><strong>repera</strong><small>Business</small></span></div></header>`;
 if(!user){
  const title={login:invitationLink?'Acepta tu invitación a Repera':'Accede a tu negocio',join:'Crea tu cuenta de deportista',register:'Crear cuenta profesional',recover:'Recuperar acceso',password:'Establecer nueva contraseña'}[view];
  const form=view==='login'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='join'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<p class="connected-hint">La aceptación se hace después de verificar el correo. Esta cuenta no crea un gimnasio ni convierte al atleta en entrenador.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Crear cuenta de deportista</button>`
   :view==='register'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<label class="connected-field">Tipo de actividad<select name="businessKind" required><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option></select></label>${field('Nombre comercial','businessName','text','minlength="2" maxlength="120"')}<p class="connected-hint">7 días de prueba gratuitos. No se pide tarjeta. Tras la prueba podrás elegir un plan; los pagos todavía no están habilitados.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Registrarme y empezar prueba</button>`
   :view==='recover'
   ?`${field('Correo electrónico','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Actualizar contraseña</button>`;
  app.innerHTML=`<div class="connected-page">${common}<main class="connected-auth"><div class="connected-card"><span class="connected-tag">PLATAFORMA PROFESIONAL</span><h1>${title}</h1><p class="connected-intro">Gestión real de organizaciones mediante Supabase. Tus entrenamientos personales permanecen en la app nativa.</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver a iniciar sesión</button>':''}${view==='login'?`${invitationLink?'<button type="button" data-view="join">Soy nuevo: crear cuenta de deportista</button>':'<button type="button" data-view="register">Crear cuenta profesional</button>'}<button type="button" data-view="recover">Olvidé mi contraseña</button>`:''}</div></div></main></div>`;
  return;
 }
 const pendingInvites=invitations.filter(i=>!i.accepted_at&&!i.cancelled_at&&new Date(i.expires_at).getTime()>Date.now());
 const ownInvites=pendingInvites.filter(i=>i.email===(user.email||'').trim().toLowerCase());
 const own=new Map(memberships.filter(m=>m.user_id===user.id&&m.status==='active').map(m=>[m.organization_id,m.role]));
 if(delegation)own.set(delegation.org_id,'admin');
 if(!delegation&&platformRole!=='platform_admin'&&
   (invitationLink||ownInvites.length||[...own.values()].includes('athlete'))&&
   ![...own.values()].some(role=>['owner','admin','coach','reception'].includes(role))){
  app.innerHTML=`<div class="connected-page"><main class="connected-auth">
   <section class="connected-card"><span class="connected-tag">REPERA · DEPORTISTAS</span>
   <h1>Tus invitaciones</h1><p>Solo tu cuenta con correo verificado puede aceptar la relación.
   No se comparten tus entrenamientos privados de forma automática.</p>${message()}
   ${ownInvites.length?ownInvites.map(i=>`<article class="connected-org">
    <div><strong>Invitación de tu centro</strong>
    <small>Perfil: ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)}
    · caduca ${escapeHTML(i.expires_at.slice(0,10))}</small></div>
    <button type="button" class="connected-primary" data-action="accept-invitation"
    data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar y vincularme</button></article>`).join(''):
     own.size?'<p class="connected-notice">Tu cuenta ya está vinculada. Puedes continuar en la app de Repera.</p>':
      '<p class="connected-hint">No hay invitaciones pendientes para este correo. Consulta al centro que te invitó.</p>'}
   <button type="button" class="connected-secondary" data-action="logout">Cerrar sesión</button>
   </section></main></div>`;
  return;
 }
 app.innerHTML=`<div class="connected-page ${delegation?'is-delegated':''}">${common}<main class="connected-workspace"><div class="connected-heading"><div><span class="connected-tag">SESIÓN AUTENTICADA · SUPABASE REPERA</span><h1>Mis organizaciones</h1><p>${escapeHTML(user.email||'Cuenta Repera')} · ${platformRole==='platform_admin'?'Administrador de plataforma · ':''}Solo se muestran negocios autorizados por la base de datos.</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button></div>${message()}${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}<section data-workspace-section="overview" class="connected-grid connected-onboarding-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div>${['owner','admin'].includes(own.get(o.id))?`<div class="connected-org-brand">${o.avatar_url?`<img class="connected-org-avatar" src="${escapeHTML(o.avatar_url)}" alt="" loading="lazy">`:`<span class="connected-org-avatar placeholder">${escapeHTML((o.name||'R').slice(0,1).toUpperCase())}</span>`}<form data-connected="rename" class="connected-inline"><input type="hidden" name="id" value="${escapeHTML(o.id)}"><label>Nombre<input name="name" value="${escapeHTML(o.name)}" maxlength="120" required></label><label>${o.kind==='personal_trainer'?'Foto del entrenador':'Logotipo del gimnasio'}<input name="avatarFile" type="file" accept="image/jpeg,image/png,image/webp"></label><label>Eslogan<input name="tagline" value="${escapeHTML(o.tagline||'')}" maxlength="160"></label><label class="connected-check"><input type="checkbox" name="discoverable" ${o.is_discoverable!==false?'checked':''}> Visible para deportistas</label><button class="connected-secondary" ${busy?'disabled':''}>Guardar</button></form></div>`:''}</article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card">${renderOrganizationCreateForm(planCatalog,(()=>{try{return JSON.parse(sessionStorage.getItem(PENDING_REGISTRATION_KEY)||'null')||{};}catch{return {};}})())}</div></section><section class="connected-card" data-workspace-section="clients" style="margin-top:22px"><h2>Clientes reales</h2><label class="connected-field">Organización<select id="connected-org-select"><option value="">Selecciona una organización</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${selectedOrg===o.id?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select></label>${selectedOrg?`<div style="margin-top:20px">${clients.length?clients.map(c=>`<article class="connected-org"><div><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email)} · ${escapeHTML(c.status)}</small></div></article>`).join(''):'<p>Sin clientes registrados en esta organización.</p>'}${['owner','admin'].includes(own.get(selectedOrg))?`<form data-connected="client">${field('Nombre del cliente','name','text','minlength="2" maxlength="120"')}${field('Correo electrónico','email','email')}<button class="connected-primary">Añadir cliente potencial</button></form>`:''}</div>`:''}</section>${selectedOrg&&["owner","admin"].includes(own.get(selectedOrg))?`<section class="connected-card" data-workspace-section="team" style="margin-top:22px"><h2>Invitar a mi organización</h2><p>La persona debe registrarse con el mismo correo verificado. Podrá aceptar la invitación al iniciar sesión. Aún no se envían correos automáticos.</p><form data-connected="invite">${field('Correo del invitado','email','email')}<label class="connected-field">Perfil<select name="role"><option value="athlete">Deportista</option><option value="coach">Entrenador</option><option value="reception">Recepción</option><option value="admin">Administrador</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button></form>${pendingInvites.filter(i=>i.organization_id===selectedOrg).length?`<p>Invitaciones pendientes: ${pendingInvites.filter(i=>i.organization_id===selectedOrg).length}</p>`:''}</section>`:''}${trainerActive()?'':renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients,memberships,busy,escapeHTML,templateId:selectedTemplateId,sessionId:editingSessionId,clientId:planningClientId,preferredDate:planningSelectedDay})}<div data-workspace-section="services">${renderServicesPanel({selectedOrg,role:own.get(selectedOrg),occurrences,passes,bookings,clients,memberships,busy,escapeHTML})}</div><section class="connected-next"><h2>Próximos módulos</h2><p>Asignación operativa de entrenadores, planes publicados, compra de bonos y reservas desde las apps móviles aún no están conectados. No se muestran datos ficticios en este espacio autenticado.</p></section></main></div>`;
 enhanceWorkspace(own);
 if(delegation){
  const org=organizations.find(o=>o.id===delegation.org_id);
  const pendingCenter=adminDirectory.find(o=>o.id===delegation.org_id&&o.registration_status==='pending');
  const hdr=app.querySelector('.connected-heading');
  if(hdr){
   const name=escapeHTML(org?.name||delegation.name||'Centro');
   const logo=org?.avatar_url&&/^https:\/\//.test(org.avatar_url)?
    `<img src="${escapeHTML(org.avatar_url)}" alt="" loading="lazy">`:
    `<span>${escapeHTML((org?.name||'R').slice(0,1))}</span>`;
   hdr.innerHTML=`<div class="business-delegate-identity"><div class="business-delegate-avatar">${logo}</div>
    <div><span class="business-delegate-eyebrow">REPERA BUSINESS · MODO ADMINISTRADOR</span>
    <h1>${name}</h1><p>${org?.kind==='personal_trainer'?'Entrenador personal':'Centro deportivo'}
    ${pendingCenter?' · Registro del propietario pendiente':''}
    · Acceso de soporte hasta ${escapeHTML(new Date(delegation.expires_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))}</p></div></div>
    <button type="button" class="business-delegate-exit" data-admin-action="exit-delegation">Volver a administración</button>`;
  }
  const root=app.querySelector('.connected-workspace');
  const nav=root?.querySelector('.business-navigation');
  if(root&&nav){
   root.classList.add('business-delegated-workspace');
   nav.querySelector('#workspace-org-select')?.closest('label')?.remove();
   const orgName=escapeHTML(org?.name||'Centro');
   const logoURL=org?.avatar_url&&/^https:\/\//.test(org.avatar_url)?escapeHTML(org.avatar_url):'';
   const avatar=logoURL?`<img src="${logoURL}" alt="">`:
    `<span class="business-sidebar-avatar">${escapeHTML((org?.name||'C').slice(0,1).toUpperCase())}</span>`;
   nav.insertAdjacentHTML('beforeend',`<div class="business-sidebar-account">
    ${avatar}<div><strong>${orgName}</strong><small>${org?.kind==='personal_trainer'?'Entrenador personal':'Gimnasio'} · Vista de soporte</small></div>
    <button type="button" data-workspace="settings" aria-label="Ajustes del centro" title="Ajustes del centro">⚙</button>
   </div>
   <div class="business-sidebar-actions">
    <button type="button" data-admin-action="exit-delegation">Volver a Repera Admin</button>
    <button type="button" data-action="logout">Cerrar sesión</button>
   </div>`);
   const content=document.createElement('div');content.className='business-delegate-content';
   root.querySelectorAll('[data-workspace-section]').forEach(section=>content.append(section));
   root.append(content);
  }
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
 if(!selectedOrg){clients=[];occurrences=[];passes=[];offers=[];attendance=[];bookings=[];professionalSessions=[];templates=[];trialRows=[];classDetails=[];groups=[];groupMembers=[];notices=[];enrollmentRequests=[];legalProfile=null;return;}
 const role=delegation?'admin':
  memberships.find(m=>m.organization_id===selectedOrg&&m.user_id===user?.id&&m.status==='active')?.role;
 const manager=['owner','admin'].includes(role);
 [clients,occurrences,passes,offers,bookings,professionalSessions,templates,trialRows,classDetails,groups,groupMembers,notices]=await Promise.all([
  auth.clients(selectedOrg,{basic:!manager}),
  auth.serviceOccurrences(selectedOrg),
  auth.servicePasses(selectedOrg),
  auth.servicePassOffers(selectedOrg),
  auth.serviceBookings(selectedOrg),
  auth.professionalSessions(selectedOrg),
  ['owner','admin','coach'].includes(role)?auth.workoutTemplates(selectedOrg):Promise.resolve([]),
  auth.organizationTrial(selectedOrg),
  auth.classDetails(selectedOrg),
  ['owner','admin','coach'].includes(role)?auth.groupList(selectedOrg):Promise.resolve([]),
  ['owner','admin','coach'].includes(role)?auth.groupMembers(selectedOrg):Promise.resolve([]),
  auth.clientNotifications(selectedOrg)]);
 const avatars=await auth.clientAvatars(selectedOrg).catch(()=>[]);
 const byId=new Map(avatars.map(a=>[a.client_id,a.avatar_url]));
 clients=clients.map(c=>({...c,avatar_url:byId.get(c.id)||c.avatar_url}));
 attendance=organizations.find(o=>o.id===selectedOrg)?.kind==='personal_trainer'&&manager
  ?await auth.trainerAttendance(selectedOrg).catch(()=>[]):[];
 legalProfile=manager?await auth.legalProfile(selectedOrg):null;
 enrollmentRequests=manager?await auth.enrollmentRequests(selectedOrg):[];
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
 else {
  const professionalIds=new Set(memberships.filter(m=>m.user_id===user?.id&&
    m.status==='active'&&['owner','admin','coach','reception'].includes(m.role))
   .map(m=>m.organization_id));
  if(!professionalIds.size)selectedOrg=null;
  else if(!professionalIds.has(selectedOrg))
   selectedOrg=organizations.find(o=>professionalIds.has(o.id))?.id||null;
 }
 // Athletes do not enter financial, fiscal and staff RPCs of a professional center.
 await loadSelectedOrg();
}
function bulkPlanSummary(form){
 if(!form)return {ok:false,message:'Abre la planificación rápida'};
 const ids=[...form.querySelectorAll('input[name="clients"]:checked')].map(x=>x.value);
 const days=[...form.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
 const template=form.querySelector('select[name="template"]')?.value||'';
 const from=form.querySelector('input[name="start"]')?.value||'';
 const to=form.querySelector('input[name="end"]')?.value||'';
 if(!/^\d{4}-\d{2}-\d{2}$/.test(from)||!/^\d{4}-\d{2}-\d{2}$/.test(to))
  return {ok:false,message:'Selecciona fechas válidas'};
 const first=Date.parse(from+'T12:00:00Z'),last=Date.parse(to+'T12:00:00Z');
 if(!Number.isFinite(first)||!Number.isFinite(last)||last<first||last-first>55*86400000)
  return {ok:false,message:'Elige un intervalo válido de máximo 8 semanas'};
 const allowed=new Set(days),countDays=Array.from({length:Math.floor((last-first)/86400000)+1},(_,i)=>
  new Date(first+i*86400000).getUTCDay()||7).filter(day=>allowed.has(day)).length;
 const count=ids.length*countDays;
 const label=ids.length+' atletas · '+countDays+' días · '+count+' entrenamientos';
 if(!template)return {ok:false,message:'Selecciona una plantilla · '+label};
 if(!ids.length)return {ok:false,message:'Selecciona al menos un atleta'};
 if(ids.length>20)return {ok:false,message:'Máximo 20 atletas por publicación'};
 if(!days.length||!countDays)return {ok:false,message:'Selecciona un día de la semana dentro del intervalo'};
 if(count>120)return {ok:false,message:label+' · supera el límite de 120'};
 return {ok:true,message:label,ids,days};
}
function refreshBulkPlanPreview(form){
 if(!form)return;
 const result=bulkPlanSummary(form);
 const preview=form.querySelector('[data-bulk-preview]');
 if(preview){preview.textContent=result.message;preview.classList.toggle('is-invalid',!result.ok);}
 const btn=form.querySelector('[data-bulk-submit]');
 if(btn)btn.disabled=busy||!result.ok;
 const selected=form.querySelector('[data-bulk-count]');
 if(selected)selected.textContent=(form.querySelectorAll('input[name="clients"]:checked').length)+' deportistas';
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
  if(command==='email-owner'&&!busy){
   busy=true;error=notice='';render();
   try{
    const delivery=await auth.sendOwnerRegistrationEmail(platformButton.dataset.id);
    notice=delivery.sent?'Correo de registro enviado. El propietario debe aceptar con su cuenta verificada.':
     'No se ha enviado el correo: '+(delivery.reason||'Entrega no confirmada')+
     '. La solicitud sigue pendiente de aceptación.';
   }catch(e){error=e.message||'No se pudo preparar el correo del propietario';}
   finally{busy=false;render();}
   return;
  }
  if(command==='center-section'){adminCenterSection=platformButton.dataset.section||'data';render();return;}
  if(command==='athlete-section'){adminAthleteSection=platformButton.dataset.section||'exercises';render();return;}
  if(command==='schedule-athlete'&&!busy){
   const profile=adminAthleteDetail;
   const c=(profile?.client_profiles||[]).find(c=>c.center_id&&c.id&&c.status==='active');
   if(!c){error='Este atleta no está vinculado a un centro activo. Debe aceptar una invitación antes de planificar.';render();return;}
   busy=true;error=notice='';render();
   try{
    await auth.platformAdminDelegate({orgId:c.center_id,reason:'Planificación deportiva desde ficha de atleta'});
    selectedOrg=c.center_id;planningClientId=c.id;planningSelectedDay=platformButton.dataset.day||'';
    activeTab='planning';adminSelectedAthlete='';adminAthleteDetail=null;
    await reload();
    notice='Planifica los entrenamientos de '+(profile?.account?.name||'este atleta')+'.';
   }catch(e){error=e.message||'No se pudo abrir la planificación';}
   finally{busy=false;render();}
   return;
  }
  if(command==='toggle-sidebar'){
   adminNavCollapsed=!adminNavCollapsed;
   try{localStorage.setItem('repera.admin.nav.collapsed',adminNavCollapsed?'1':'0');}catch{}
   render();return;
  }
  if(command==='view-org'){
   adminSelectedOrg=platformButton.dataset.id;adminCenterSection='data';adminSelectedAthlete='';adminAthleteDetail=null;
   adminAthleteWorkouts=[];adminCenterDetail=null;adminTab='centers';error=notice='';render();
   try{adminCenterDetail=await auth.platformAdminCenterDetail(adminSelectedOrg);}
   catch(e){error=e.message||'No se pudieron cargar los datos del centro';}
   render();return;
  }
  if(command==='back-org'){adminSelectedOrg='';adminCenterDetail=null;render();return;}
  if(command==='view-athlete'){
   adminSelectedAthlete=platformButton.dataset.id;adminAthleteSection='exercises';adminSelectedOrg='';adminCenterDetail=null;
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
 const tab=event.target.closest('[data-workspace]');if(tab){activeTab=tab.dataset.workspace;businessDialog='';clientEditorOpen=false;setWorkspaceRoute();render();return;}
 const mode=event.target.closest('[data-view]');if(mode){view=mode.dataset.view;error=notice='';render();return;}
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 const trainer=trainerActive();
 const setting=event.target.closest('[data-settings-section]');if(setting){settingsSection=setting.dataset.settingsSection==='plan'?'plan':'profile';render();return;}
 if(action==='close-business-dialog'||trainer&&(action==='back-classes'||action==='back-groups')){businessDialog='';selectedClassId=null;selectedGroupId=null;render();return;}
 if(action==='trainer-session'&&trainer){selectedClientId=actionable.dataset.id;businessDialog='trainer-session';render();return;}
 if(action==='new-date-appointment'&&trainer){dialogDay=actionable.dataset.day;businessDialog='new-appointment';render();return;}
 if(action==='calendar-today'){calendarMonth='';render();return;}
 if(action==='bulk-mode'){bulkMode=actionable.dataset.mode==='template'?'template':'custom';render();return;}
 if(action==='add-planning'&&trainer){if(actionable.dataset.id){selectedClientId=actionable.dataset.id;planningClientId=selectedClientId;}bulkMode='custom';businessDialog='bulk';render();return;}
 if(action==='delete-session'&&!busy){if(!confirm('¿Eliminar este entrenamiento programado? No se borrarán actividades ya realizadas por el deportista.'))return;busy=true;render();try{await auth.cancelProfessionalSession(actionable.dataset.id);await loadSelectedOrg();notice='Entrenamiento retirado de la planificación.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='end-client'&&trainer&&!busy){const client=clients.find(c=>c.id===actionable.dataset.id);if(!client)return;if(!confirm('Confirma que el contrato profesional ya ha vencido. La cuenta personal del deportista y sus suscripciones independientes se conservarán.'))return;busy=true;render();try{await auth.updateClientProfile({orgId:selectedOrg,id:client.id,name:client.name,email:client.email,phone:client.phone||'',notes:client.notes||'',avatar:client.avatar_url||'',status:'cancelled'});await loadSelectedOrg();notice='Relación profesional finalizada; la cuenta personal no se ha cancelado.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='detail-client'){selectedClientId=actionable.dataset.id;planningClientId=selectedClientId;clientSection='training';clientEditorOpen=false;trainerActivityMonth='';trainerActivityDay='';sharedHistory=[];activeTab='clients';businessDialog='';setWorkspaceRoute();render();try{
    const client=clients.find(c=>c.id===selectedClientId);
    sharedHistory=client?.account_deleted_at
     ?await auth.archivedAthleteResults({orgId:selectedOrg,clientId:selectedClientId})
     :await auth.sharedClientHistory({orgId:selectedOrg,clientId:selectedClientId});
   }catch(e){error='El historial histórico o privado no está disponible para este profesional.';}render();return;}
 if(action==='back-clients'){sharedHistory=[];clientEditorOpen=false;selectedClientId=null;planningClientId=null;editingSessionId=null;selectedTemplateId=null;activeTab='clients';setWorkspaceRoute();render();return;}
 if(action==='client-section'){clientSection=actionable.dataset.section||'training';clientEditorOpen=false;render();return;}
 if(action==='trainer-day'&&trainer){trainerActivityDay=actionable.dataset.day;trainerActivityMonth=trainerActivityDay.slice(0,7);clientEditorOpen=false;render();return;}
 if(action==='trainer-month'&&trainer){const month=trainerActivityMonth||new Date().toLocaleDateString('sv-SE').slice(0,7);const d=new Date(month+'-01T12:00:00');d.setMonth(d.getMonth()+(Number(actionable.dataset.step)||0));trainerActivityMonth=d.toLocaleDateString('sv-SE').slice(0,7);trainerActivityDay=trainerActivityMonth+'-01';clientEditorOpen=false;render();return;}
 if(action==='close-client-editor'&&trainer){clientEditorOpen=false;selectedTemplateId=null;editingSessionId=null;render();return;}
 if(action==='detail-group'){selectedGroupId=actionable.dataset.id;selectedClassId=null;if(trainer)businessDialog='group';else activeTab='services';render();return;}
 if(action==='back-groups'){selectedGroupId=null;activeTab='services';render();return;}
 if(action==='detail-occurrence'){selectedGroupId=null;classEditorId=null;selectedClassId=actionable.dataset.id;if(trainer)businessDialog='occurrence';else activeTab='services';render();return;}
 if(action==='back-classes'){classEditorId=null;selectedClassId=null;activeTab='services';render();return;}
 if(action==='open-class-calendar'){selectedClassId=null;classMode='calendar';activeTab=trainer?'overview':'services';setWorkspaceRoute();render();return;}
 if(action==='calendar-mode'){classMode=actionable.dataset.mode==='list'?'list':'calendar';render();return;}
 if(action==='calendar-prev'||action==='calendar-next'){
  const first=(calendarMonth?new Date(calendarMonth+'-01T12:00:00'):new Date());
  first.setDate(1);first.setMonth(first.getMonth()+(action==='calendar-next'?1:-1));
  calendarMonth=first.toLocaleDateString('sv-SE').slice(0,7);render();return;
 }
 if(action==='publish-class-plan'){classEditorId=actionable.dataset.id;selectedClassId=actionable.dataset.id;if(trainer)businessDialog='occurrence';else activeTab='services';render();return;}
 if(action==='plan-client'){planningClientId=actionable.dataset.id;selectedClientId=planningClientId;clientSection='training';activeTab=trainer?'clients':'planning';clientEditorOpen=trainer;planningSelectedDay=actionable.dataset.day||trainerActivityDay||'';selectedTemplateId=null;editingSessionId=null;setWorkspaceRoute();render();if(trainer)app.querySelector('#client-workout-editor')?.scrollIntoView({behavior:'smooth',block:'start'});return;}
 if(action==='find-class-for-client'){selectedClientId=actionable.dataset.id;selectedClassId=null;activeTab='services';classMode='list';notice='Selecciona una clase para inscribir a este deportista con un bono válido.';render();return;}
 if(action==='refresh-enrollments'&&!busy&&selectedOrg){
  busy=true;error='';render();
  try{
   enrollmentRequests=await auth.enrollmentRequests(selectedOrg);
   notice='Solicitudes actualizadas.';
  }catch(e){error=e.message||'No se pudo consultar las solicitudes';}
  finally{busy=false;render();}
  return;
 }
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
   refreshBulkPlanPreview(form);
  }
  return;
 }
 if(action==='toggle-pass-offer'&&!busy){
  const offer=offers.find(o=>o.id===actionable.dataset.id);
  if(!offer)return;
  busy=true;error=notice='';render();
  try{await auth.changeServicePassOffer({id:offer.id,isActive:!offer.is_active});await loadSelectedOrg();
   notice='Disponibilidad de la tarifa actualizada.';}catch(e){error=e.message;}
  finally{busy=false;render();}
  return;
 }
 if(action==='invite-client'&&!busy){const c=clients.find(c=>c.id===actionable.dataset.id);
  if(!c||c.user_id)return;busy=true;render();
  try{
   const id=await auth.issueInvitation({orgId:selectedOrg,email:c.email,role:'athlete'});
   let emailResult={sent:false,reason:'Envío pendiente'};
   try{emailResult=await auth.sendInvitationEmail(id);}
   catch(e){emailResult={sent:false,reason:e.message||'Envío no confirmado'};}
   await reload();
   notice=emailResult.sent?'Invitación enviada por correo. La vinculación queda pendiente de aceptación.':
    'Invitación creada, pero no enviada: '+emailResult.reason+'. La persona podrá aceptarla desde su cuenta verificada.';
  }catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='toggle-pass-offer'&&!busy){
  busy=true;error=notice='';render();
  try{
   await auth.changeServicePassOffer({id:actionable.dataset.id,isActive:actionable.dataset.active!=='true'});
   await loadSelectedOrg();notice='Visibilidad del bono actualizada.';
  }catch(e){error=e.message||'No se pudo actualizar el bono';}
  finally{busy=false;render();}
  return;
 }
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
 if(action==='use-template'){selectedTemplateId=actionable.dataset.id;editingSessionId=null;clientEditorOpen=trainer;clientSection='training';activeTab=trainer?'clients':'planning';setWorkspaceRoute();render();return;}
 if(action==='edit-session'){editingSessionId=actionable.dataset.id;selectedTemplateId=null;clientEditorOpen=trainer;const session=professionalSessions.find(s=>s.id===editingSessionId);if(trainer&&session){selectedClientId=session.client_id;planningClientId=selectedClientId;clientSection='training';}activeTab=trainer?'clients':'planning';setWorkspaceRoute();render();if(trainer)app.querySelector('#client-workout-editor')?.scrollIntoView({behavior:'smooth',block:'start'});return;}
 if(action==='accept-invitation'&&!busy){busy=true;error=notice='';render();try{await auth.acceptInvitation(actionable.dataset.id);await reload();notice='Invitación aceptada. Tu relación con el profesional ya consta en Supabase.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='logout'){busy=true;render();try{if(delegation)await auth.platformAdminEndDelegation();await auth.signOut();delegation=null;user=null;organizations=[];memberships=[];invitations=[];view='login';notice='Sesión cerrada';}catch(e){user=null;organizations=[];memberships=[];view='login';notice='Sesión local cerrada. No se pudo confirmar el cierre remoto.';}finally{busy=false;render();}}
});
app.addEventListener('keydown',event=>{
 const athleteRow=event.target.closest('tr.pa-athlete-row[data-admin-action],.business-client-table tr[data-action="detail-client"]');
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
   refreshBulkPlanPreview(form);
  }
  return;
 }
 if(event.target.closest('form[data-connected="bulk-training"]')&&
    event.target.matches('[name="clients"],[name="template"],[name="weekdays"],[name="start"],[name="end"]')){
  refreshBulkPlanPreview(event.target.closest('form'));
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
 if(!['connected-org-select','workspace-org-select'].includes(event.target.id))return;selectedOrg=event.target.value||null;businessDialog='';clientEditorOpen=false;selectedClientId=null;selectedClassId=null;selectedGroupId=null;planningClientId=null;sharedHistory=[];activeTab='overview';selectedTemplateId=null;editingSessionId=null;error='';clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];
 if(selectedOrg){try{await loadSelectedOrg();}catch(e){error=e.message;}}
 setWorkspaceRoute();render();});
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
   if(action==='center-visibility'){
    await auth.platformAdminSetVisibility({orgId:values.get('org_id'),
     visible:values.get('discoverable')==='true'});
    notice='Visibilidad actualizada; la situación del propietario no ha cambiado.';
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
   if(['status','center-visibility'].includes(action)&&adminSelectedOrg)adminCenterDetail=await auth.platformAdminCenterDetail(adminSelectedOrg);
  }catch(e){error=e.message||'No se pudo completar la operación';}
  finally{busy=false;render();}
  return;
 }
 const f=event.target.closest('form[data-connected]');if(!f)return;event.preventDefault();if(busy)return;
 const action=f.dataset.connected,data=new FormData(f),intent=event.submitter?.dataset.intent||'publish';
 if(action==='bulk-custom'){
  const ids=[...f.querySelectorAll('input[name="clients"]:checked')].map(x=>x.value);
  const weekdays=[...f.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
  const from=String(data.get('start')||''),to=String(data.get('end')||'');
  const days=(Date.parse(to+'T12:00:00Z')-Date.parse(from+'T12:00:00Z'))/86400000;
  const selectedDays=Number.isFinite(days)&&days>=0&&days<=55?Array.from({length:days+1},(_,i)=>{
   const d=new Date(from+'T12:00:00Z');d.setUTCDate(d.getUTCDate()+i);
   return weekdays.includes(d.getUTCDay()||7)?1:0;
  }).reduce((a,b)=>a+b,0):0;
  const preview=f.querySelector('[data-custom-preview]');
  if(ids.length<1||ids.length>20||!selectedDays||ids.length*selectedDays>120){
   if(preview){preview.textContent='Selecciona entre 1 y 20 atletas, un rango máximo de 8 semanas y hasta 120 sesiones.';preview.classList.add('is-invalid');}
   return;
  }
 }
 if(action==='bulk-training'){
  const valid=bulkPlanSummary(f);
  if(!valid.ok){
   const preview=f.querySelector('[data-bulk-preview]');
   if(preview){preview.textContent=valid.message;preview.classList.add('is-invalid');}
   preview?.scrollIntoView({behavior:'smooth',block:'nearest'});
   return;
  }
 }
 let prescription=null;
 try{if(['publish-session','publish-class-plan','bulk-custom'].includes(action))prescription=canonicalPrescription(validatePrescription(readPrescription(f)));}catch(e){
  const preview=f.querySelector('[data-custom-preview]');if(preview){preview.textContent=e.message;preview.classList.add('is-invalid');return;}
  error=e.message;notice='';render();return;
 }
 busy=true;error=notice='';render();
 try{
  if(action==='login'){user=await auth.signIn(data.get('email'),data.get('password'));await reload();await finalizePendingRegistration();}
  if(action==='join'){
   const result=await auth.signUp(data.get('email'),data.get('password'),redirectTo());
   if(result.confirmationRequired){view='login';notice='Revisa tu email y verifica la cuenta. Después inicia sesión para aceptar la invitación sin crear ninguna empresa.';}
   else{user=await auth.currentUser();await reload();notice='Cuenta creada. Confirma la vinculación desde la tarjeta de invitación.';}
  }
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
  if(action==='invite'){
   const id=await auth.issueInvitation({orgId:selectedOrg,email:data.get('email'),role:data.get('role')});
   let delivery={sent:false,reason:'Envío pendiente'};
   try{delivery=await auth.sendInvitationEmail(id);}catch(e){delivery={sent:false,reason:e.message||'Envío no confirmado'};}
   await reload();
   notice=delivery.sent?'Invitación enviada. Solo se vinculará tras la aceptación del destinatario.':
    'Invitación guardada, pero no enviada: '+delivery.reason+'. El usuario puede aceptarla desde su cuenta.';
  }
  if(action==='publish-session'){
   if(intent==='template'){
    const name=data.get('templateName')||data.get('title');
    if(selectedTemplateId)await auth.updateWorkoutTemplate({id:selectedTemplateId,orgId:selectedOrg,name,description:data.get('templateDescription'),prescription});
    else await auth.createWorkoutTemplate({orgId:selectedOrg,name,description:data.get('templateDescription'),prescription,userId:user.id});
    selectedTemplateId=null;notice='Plantilla guardada en tu biblioteca.';
   }else if(editingSessionId){
    await auth.updateProfessionalSession({id:editingSessionId,date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    await auth.setProfessionalSessionTime(editingSessionId,String(data.get('time')||''));
    editingSessionId=null;notice='Cambios del entrenamiento individual guardados.';
   }else{
    const sessionId=await auth.publishProfessionalSession({orgId:selectedOrg,clientId:data.get('client'),date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    await auth.setProfessionalSessionTime(sessionId,String(data.get('time')||''));
    selectedTemplateId=null;notice='Entrenamiento profesional publicado.';
   }
   await reload();
   if(trainerActive()&&intent==='publish')clientEditorOpen=false;
  }
  if(action==='bulk-custom'){
   const ids=[...f.querySelectorAll('input[name="clients"]:checked')].map(x=>x.value);
   const weekdays=[...f.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
   const result=await auth.bulkPublishCustomTraining({
     orgId:selectedOrg,clientIds:ids,start:data.get('start'),end:data.get('end'),weekdays,
     title:data.get('title'),instructions:data.get('instructions')||'',prescription});
   await loadSelectedOrg();businessDialog='';
   notice='Planificación guardada: '+(result.created||0)+' sesiones'+(result.skipped?' · '+result.skipped+' existentes sin duplicar':'')+'.';
  }
  if(action==='bulk-training'){
   const ids=[...f.querySelectorAll('input[name="clients"]:checked')].map(x=>x.value);
   const weekdays=[...f.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
   const result=await auth.bulkPublishTraining({
    orgId:selectedOrg,templateId:data.get('template'),clientIds:ids,
    start:data.get('start'),end:data.get('end'),weekdays,
    requestId:crypto.randomUUID()});
   await loadSelectedOrg();businessDialog='';
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
   await loadSelectedOrg();businessDialog='';notice='Sesiones creadas: '+(Array.isArray(created)?created.length:1);
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
   const existing=clients.find(x=>x.id===data.get('client'));
   await auth.updateClientProfile({orgId:selectedOrg,id:data.get('client'),name:data.get('name'),email:data.get('email'),
    phone:existing?.phone||'',notes:existing?.notes||'',avatar:existing?.avatar_url||'',status:data.get('status')});
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
  if(action==='issue-offline-pass'){
   if(data.get('confirmed')!=='yes')throw Error('Confirma la asignación fuera de Repera.');
   await auth.issueOfflinePass({orgId:selectedOrg,clientId:data.get('client'),offerId:data.get('offer')});
   await loadSelectedOrg();notice='Bono asignado. Registrado como gestión externa; no se ha efectuado ningún cobro en Repera.';
  }
  if(action==='trainer-attendance'){
   await auth.recordTrainerAttendance({orgId:selectedOrg,
     clientId:passes.find(p=>p.id===data.get('pass'))?.client_id,
     passId:data.get('pass'),occurrenceId:data.get('occurrence')||null,note:data.get('note')||''});
   await loadSelectedOrg();businessDialog='';notice='Sesión realizada registrada. Se ha descontado un crédito solo si no había reserva ya descontada.';
  }
  if(action==='create-pass-offer'){
    await auth.createServicePassOffer({orgId:selectedOrg,name:data.get('name'),kind:data.get('kind'),credits:Number(data.get('credits')),validityDays:Number(data.get('validityDays')),priceCents:Math.round(Number(data.get('price'))*100)});
    await loadSelectedOrg();notice='Bono publicado en el catálogo. La compra sigue pendiente de activar la pasarela de pago.';
  }
  if(action==='courtesy-pass'){
   await auth.grantCourtesyPass({orgId:selectedOrg,clientId:data.get('client'),kind:data.get('kind'),credits:Number(data.get('credits')),validUntil:data.get('until')+'T23:59:59'});
   await reload();notice='Bono de cortesía registrado, sin cobro.';
  }
  if(action==='client'){
   await auth.addClient({orgId:selectedOrg,name:data.get('name'),email:data.get('email'),userId:user.id});
   let delivery={sent:false,reason:'Invitación sin enviar'};
   try{
    const invitation=await auth.issueInvitation({orgId:selectedOrg,email:data.get('email'),role:'athlete'});
    try{delivery=await auth.sendInvitationEmail(invitation);}
    catch(e){delivery={sent:false,reason:e.message||'Envío no confirmado'};}
   }catch(e){delivery={sent:false,reason:e.message||'No se pudo preparar la invitación'};}
   clients=await auth.clients(selectedOrg);
   notice=delivery.sent?'Cliente pendiente e invitación enviada. La vinculación requiere su aceptación.':
    'Ficha creada. El cliente sigue pendiente; email sin confirmar: '+delivery.reason+'.';
  }
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
window.addEventListener('popstate',async()=>{const old=selectedOrg;restoreWorkspaceRoute();businessDialog='';if(old!==selectedOrg&&user){try{await loadSelectedOrg();}catch(e){error=e.message;}}render();});
async function boot(){
 restoreWorkspaceRoute();busy=true;render();
 try{
  if(await auth.acceptRecoveryFragment(globalThis.location?.hash||'')){
   history.replaceState(null,'',location.pathname+location.search);view='password';
   // Recovery JWT is valid; keep password screen rather than normal admin UI.
  }else{user=await auth.currentUser();if(user){await reload();await finalizePendingRegistration();}}
 }catch(e){auth.clear();error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';}
 finally{busy=false;render();}
}
boot();
