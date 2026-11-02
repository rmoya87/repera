import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
import {slugFromName,uniqueSlug,visiblePlans,priceLabel} from '../core/business-profile.js';
import {renderPlanOptions,renderOrganizationFields,renderOrganizationCreateForm,renderPlanAdministration} from './business-onboarding.js';
import {renderProfessionalPlanning,renderClientWorkoutFullscreen} from './connected-planning.js';
import {navIcon} from './nav-icons.js';
import {renderPlatformAdmin,paymentCSV} from './platform-admin.js';
import {renderBusinessHome,renderClient360,renderClasses360,renderNewGroupModal,renderNewClassModal,renderNewClientWorkoutModal,renderEditClassModal,renderEnrollClassModal,renderPublishClassPlanModal,renderAssignClassTrainingModal,parseWeekSlotKey,weekSlotGrid} from './management-360.js';
import {renderTrainerPassPanel,trainerSeatInfo,timeToMinute,renderPassOfferModal} from './trainer-pass-panel.js';
import {renderGymPassPanel} from './gym-pass-panel.js';
import {renderAssignPassModal} from './client-passes.js';
import {renderBillingDashboard} from './billing-dashboard.js';
import {handleEditorClick,handleEditorSearch,readPrescription,validatePrescription,canonicalPrescription,emptyPrescription,editorMarkup,MOVEMENTS,exerciseThumbHTML,resetEditorPanels,readSessionMeta,withSessionMeta} from './workout-editor.js';
import {resolveAssignScopeIds} from './assign-scope.js';
import {
 pendingAthleteInvite,parseWhatsappE164,renderServicesSettings,
 beginInvitationWhatsappPopup,finishInvitationWhatsappPopup,
} from './invitation-share.js';
import {
 renderInviteModal,renderQuickWorkoutModal,renderGymAssignmentDialog,renderNotificationsDrawer,
 todayISO,countQuickWorkoutSessions,agendaMonthChromeHTML,
} from './trainer-agenda.js';
import {renderTrainerWorkoutsLibrary,mergePrescriptionBlocks} from './trainer-workouts.js';
import {renderOperationSettings,renderDayProgramPanel,profileDefaults} from './operation-settings.js';
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
let user=null,platformRole=null,platformOrgs=[],organizations=[],memberships=[],invitations=[],clients=[],occurrences=[],passes=[],offers=[],attendance=[],bookings=[],passEvents=[],professionalSessions=[],templates=[],selectedOrg=null,trialRows=[],classDetails=[],groups=[],groupMembers=[],notices=[],enrollmentRequests=[],sharedHistory=[],chatMessages=[],selectedClientId=null,clientSection='training',trainerActivityMonth='',trainerActivityDay='',clientEditorOpen=false,selectedClassId=null,selectedGroupId=null,classMode='calendar',calendarMonth='',classEditorId=null,planningClientId=null,planningSelectedDay='',activeTab='overview',selectedTemplateId=null,editingSessionId=null,legalProfile=null,planCatalog=[],view='login',busy=false,error='',notice='',businessDialog='',dialogDay='',settingsSection='profile',bulkMode='custom',lastInviteShare=null,agendaView='month',agendaDay='',clientQuery='',showInviteModal=false,inviteDraft={name:'',email:'',phone:''},inviteEmailError='',gymAssignments=[],quickWorkoutClient='',seedPrescription=null,copyBrowseClientId='',libraryTemplateId=null,draftSessionMeta=null,whatsappDraft=null,agendaRoom='',expandedOccurrenceId='',selectedOfferId='',assignClassDay='',assignTemplateId='',assignOnlyWithout=false,assignPreselectedIds=[],assignScope='one',operationSettings=null,facilityRooms=[],activityTypes=[];
const inviteEmailIssue=raw=>{
 const t=String(raw||'');
 if(/CLIENT_ALREADY_LINKED/i.test(t)||/vinculado a una cuenta/i.test(t))
  return 'Este correo ya está vinculado a una cuenta en tu centro. Ábrelo desde Socios o pídele que use ese acceso.';
 if(/ALREADY_A_MEMBER/i.test(t)||/ya forma parte/i.test(t))
  return 'Esta persona ya forma parte de tu centro.';
 if(/clients_org_email_uq|duplicate key.*clients_org_email|ya tiene ficha/i.test(t))
  return 'Este correo ya tiene ficha en tu centro. Ábrela en Socios para reenviar la invitación.';
 if(/INVALID_EMAIL|correo electrónico/i.test(t))return 'Revisa el correo electrónico.';
 return '';
};
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador personal',sports_center:'Gimnasio'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
/** Errores de reserva / apuntar a clase (Business). */
const friendlyPassBookError=raw=>{
 const t=String(raw||'');
 if(/PASS_OUTSIDE_SLOT/i.test(t))
  return 'Ese plan no cubre esta clase (franja o tipo de acceso). Revisa el plan del socio o crea uno de clases.';
 if(/NO_VALID_PASS/i.test(t))return 'No hay un plan activo con crédito válido para esa clase.';
 if(/NO_AVAILABILITY|CLASS_FULL/i.test(t))return 'La clase está completa.';
 if(/ALREADY_BOOKED|CLASS_FULL_OR_DUPLICATE/i.test(t))return 'Ya está apuntado a esta clase.';
 if(/OCCURRENCE_UNAVAILABLE|CLASS_UNAVAILABLE/i.test(t))return 'Esa clase ya no admite inscripción.';
 if(/BOOKING_NOT_OPEN_YET/i.test(t))return 'Todavía no está abierta la inscripción a esta clase.';
 if(/NOT_A_MEMBER|NOT_OWN_PASS|NOT_AUTHORIZED/i.test(t))return 'Sin permiso para apuntar con ese plan.';
 return '';
};
/** Mensajes cortos para UI (sin volcado SQL/PostgREST). */
const shortFlash=raw=>{
 const t=String(raw||'').trim();
 if(!t)return '';
 const book=friendlyPassBookError(t);if(book)return book;
 if(/null value in column ["']?description/i.test(t))return 'No se pudo guardar la clase.';
 if(/null value in column ["']?location/i.test(t))return 'No se pudo guardar la ubicación.';
 if(/COACH_NOT_AUTHORIZED|Elige un entrenador/i.test(t))return 'Elige un entrenador del equipo.';
 if(/COACH_TIME_OVERLAP/i.test(t))return 'Ese entrenador ya tiene clase en ese horario.';
 if(/ROOM_OVERLAP/i.test(t))return 'Esa sala ya tiene otra actividad en ese horario.';
 if(/CAPACITY_EXCEEDED/i.test(t))return 'El aforo supera la capacidad de la sala.';
 if(/OPEN_ACCESS_DISABLED/i.test(t))return 'Activa Open gym en Ajustes → Operación.';
 if(/ROOMS_DISABLED/i.test(t))return 'Activa salas en Ajustes → Operación.';
 if(/INVALID_SERIES/i.test(t))return 'Revisa horario, duración o repetición.';
 if(/NOT_AUTHORIZED|42501/i.test(t))return 'Sin permiso para esta acción.';
 if(/WHATSAPP_INVALID|Número de WhatsApp inválido/i.test(t))
  return 'Número de WhatsApp inválido. Usa prefijo país, p. ej. +34600111222.';
 if(/CLIENT_ALREADY_LINKED/i.test(t))return 'Este correo ya está vinculado a una cuenta en tu centro.';
 if(/ALREADY_A_MEMBER/i.test(t))return 'Esta persona ya forma parte de tu centro.';
 if(/clients_org_email_uq|duplicate key.*clients_org_email/i.test(t))
  return 'Este correo ya tiene ficha en tu centro.';
 if(/violates not-null|duplicate key|PGRST|postgres|sqlstate/i.test(t))
  return t.split(/[\n.]/).map(s=>s.trim()).find(Boolean)?.slice(0,120)||'No se pudo completar.';
 return t.length>140?t.slice(0,137)+'…':t;
};
/** Un solo chip (error gana a aviso). Usado en login/auth; en workspace preferir flashChip. */
const message=()=>{
 const kind=error?'error':(notice?'notice':'');
 if(!kind)return '';
 const text=shortFlash(error||notice);
 return `<p class="connected-${kind}" role="${kind==='error'?'alert':'status'}">${escapeHTML(text)}</p>`;
};
/** Chip de cabecera/modal con × para cerrar. Evita .connected-notice suelto (duplicados visuales). */
const flashChip=(where='heading')=>{
 const kind=error?'error':(notice?'notice':'');
 if(!kind)return '';
 const text=shortFlash(error||notice);
 const cls=where==='dialog'?'pt-dialog-flash':'pt-heading-flash';
 const attr=where==='dialog'?'data-dialog-flash':'data-heading-flash';
 return `<div ${attr} class="${cls} is-${kind}" role="${kind==='error'?'alert':'status'}">
  <span class="pt-flash-text">${escapeHTML(text)}</span>
  <button type="button" class="pt-flash-close" data-action="dismiss-flash" aria-label="Cerrar aviso">×</button>
 </div>`;
};
const scrubFlashDupes=root=>{
 if(!root)return;
 root.querySelectorAll('[data-workspace-flash],[data-heading-flash],[data-dialog-flash]').forEach(el=>el.remove());
 // Restos sueltos bajo el menú / en el workspace (nunca dentro de forms/cards de contenido).
 [...root.children].forEach(el=>{
  if(el.matches?.('.connected-error,.connected-notice,.business-navigation,.pt-nav-row'))el.remove();
 });
 root.querySelectorAll(':scope > .connected-error, :scope > .connected-notice').forEach(el=>el.remove());
};
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname+location.search;
const inviteId=new URLSearchParams(location.search).get('invitation')||'';
const invitationLink=/^[0-9a-f-]{36}$/i.test(inviteId);

const trainerActive=()=>organizations.find(o=>o.id===selectedOrg)?.kind==='personal_trainer';
function restoreWorkspaceRoute(){
 const p=new URLSearchParams(location.search),section=p.get('seccion'),client=p.get('cliente'),org=p.get('espacio');
 if(org&&/^[0-9a-f-]{36}$/i.test(org))selectedOrg=org;
 if(section==='services')activeTab='overview';
 else if(['overview','clients','planning','bonos','tarifas','facturacion','team','settings','workouts'].includes(section||''))activeTab=section;
 else if(['billing','analytics'].includes(section||''))activeTab='overview';
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
function defaultAppointmentSlot(dayIso){
 const day=/^\d{4}-\d{2}-\d{2}$/.test(dayIso)?dayIso:todayISO();
 const pad=n=>String(n).padStart(2,'0');
 const fmt=d=>`${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
 let start=new Date(`${day}T10:00:00`);
 const now=new Date();
 if(day===todayISO()){
  start=new Date(now.getTime()+55*60*1000);
  start.setSeconds(0,0);
  start.setMinutes(start.getMinutes()<30?30:0);
  if(start.getMinutes()===0)start.setHours(start.getHours()+1);
  if(start.getHours()>=22){start.setDate(start.getDate()+1);start.setHours(10,0,0,0);}
 }
 const end=new Date(start.getTime()+60*60*1000);
 return {start:fmt(start),end:fmt(end)};
}
function asUuid(value){
 if(typeof value==='string'&&/^[0-9a-f-]{36}$/i.test(value))return value;
 if(Array.isArray(value)&&value.length)return asUuid(value[0]);
 if(value&&typeof value==='object')return asUuid(value.id||value.pass_id||value.invitation_id||'');
 return '';
}
const asPassId=asUuid;
function trainerDialogMarkup({manager,members}){
 if(!trainerActive()||!businessDialog)return '';
 const iso=/^\d{4}-\d{2}-\d{2}$/.test(dialogDay)?dialogDay:todayISO();
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
  ${eligible.length?'':'<p>No hay saldo disponible. Asigna un plan desde Planes.</p>'}</form>`:'<p>Cliente no encontrado.</p>';
 }else if(businessDialog==='new-appointment'){
  title='Nueva cita';
  const pool=clients.filter(c=>!c.account_deleted_at&&['active','trial','paused'].includes(c.status))
   .slice().sort((a,b)=>(b.user_id?1:0)-(a.user_id?1:0)||a.name.localeCompare(b.name,'es'));
  const linked=pool.filter(c=>c.user_id&&c.status==='active');
  const preClient=quickWorkoutClient||selectedClientId||'';
  const clientPasses=passes.filter(p=>p.status==='active'&&p.kind==='appointment'&&p.remaining_credits>0&&Date.parse(p.valid_until)>Date.now());
  const slot=defaultAppointmentSlot(iso);
  inner=`<form data-connected="service-occurrence" class="business-form pt-sheet-form">
  <div class="pt-sheet-hero"><p>Individual: elige cliente vinculado para que la vea en la app como sesión personal contigo.</p></div>
  <label class="connected-field">Tipo<select name="kind" data-appt-kind>
   <option value="appointment" selected>Individual · 1:1</option>
   <option value="class">Grupo</option>
  </select></label>
  <label class="connected-field">Título<input name="title" value="Sesión personal" minlength="2" maxlength="120" required></label>
  <div class="pt-sheet-grid">
   <label class="connected-field">Inicio<input name="start" type="datetime-local" value="${slot.start}" required></label>
   <label class="connected-field">Fin<input name="end" type="datetime-local" value="${slot.end}" required></label>
  </div>
  <div data-appt-group-fields hidden>
   <label class="connected-field">Aforo<input name="capacity" type="number" min="2" max="200" value="8"></label>
  </div>
  <div data-appt-client-fields>
   <label class="connected-field">Asignar a cliente<select name="client">
    <option value="">Sin asignar (solo en tu agenda)</option>
    ${pool.map(c=>{
     const tag=!c.user_id?' · sin app':c.status!=='active'?' · '+c.status:'';
     return `<option value="${escapeHTML(c.id)}" ${c.id===preClient?'selected':''}>${escapeHTML(c.name)}${tag}</option>`;
    }).join('')}
   </select></label>
   <label class="connected-field">Bono a descontar<select name="pass" data-appt-pass>
    <option value="">Automático · bono activo o cortesía 1 sesión</option>
    ${clientPasses.map(p=>{
     const who=clients.find(c=>c.id===p.client_id)?.name||'Cliente';
     return `<option value="${escapeHTML(p.id)}" data-client="${escapeHTML(p.client_id)}">${escapeHTML(who)} · ${p.remaining_credits>=9000?'ilimitado':p.remaining_credits+' ses.'}</option>`;
    }).join('')}
   </select></label>
   <p class="connected-hint">Al asignar: se reserva la plaza y el cliente la ve en Center como cita contigo. Sin bono y con vínculo activo se crea 1 crédito de cortesía.</p>
  </div>
  <label class="connected-field">Coach<select name="coach">${members.map(m=>`<option value="${escapeHTML(m.user_id)}">${escapeHTML(m.label)}</option>`).join('')}</select></label>
  <input type="hidden" name="repeat" value="none"><input type="hidden" name="repeatCount" value="1">
  <button type="submit" class="connected-primary" ${!manager||!members.length?'disabled':''}>Crear cita</button>
  ${!linked.length?'<p class="connected-hint">Para que aparezca en la app el cliente debe estar vinculado y activo.</p>':''}
  </form>`;
 }else if(businessDialog==='occurrence'){
  title='Detalle de cita o grupo';
  inner=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches:members,selected:selectedClassId,classEditor:classEditorId===selectedClassId,manager});
 }else if(businessDialog==='group'){
  title='Datos del grupo';
  inner=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches:members,selectedGroup:selectedGroupId,manager});
 }else{
  // edit-class / publish-class-plan / new-class / etc. los pinta enhanceWorkspace.
  // No devolver un overlay vacío: tapa el modal real y parece «otra página».
  return '';
 }
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet" role="dialog" aria-modal="true" aria-label="${title}"><div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Repera</span><h2>${title}</h2></div><button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div><div class="business-dialog-scroll pt-sheet-body">${inner}</div></section></div>`;
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
 return `<section class="connected-card business-subscriptions"><h2>${head}</h2><p>Elige el plan que encaje contigo. Seleccionar solo guarda tu interés: aún no hay cobro en la plataforma.</p><div class="business-prices">${rows||'<p>No hay planes publicados ahora.</p>'}</div></section>`;
}
function enhanceWorkspace(own){
 const root=app.querySelector('.connected-workspace');if(!root)return;
 root.querySelector('.connected-next')?.remove();
 const org=organizations.find(o=>o.id===selectedOrg);
 const kind=org?.kind,trainer=kind==='personal_trainer',manager=['owner','admin'].includes(own.get(selectedOrg));
 const seat=trainerSeatInfo({clients,trials:trialRows,plans:planCatalog});
 const visibleOrganizations=delegation?organizations.filter(x=>x.id===delegation.org_id):organizations;
 const page=app.querySelector('.connected-page');
 if(page){
  page.classList.toggle('is-pt-app',!!trainer);
  page.classList.toggle('is-gym-app',kind==='gym'||kind==='sports_center');
 }
 // Mismo patrón PT/gym: Ajustes solo vía identidad. Agenda del gym vive en Inicio.
 if(activeTab==='planning'||activeTab==='bonos')activeTab=activeTab==='bonos'?'tarifas':'workouts';
 if(activeTab==='services')activeTab='overview';
 const tabs=org?[
  ['overview',trainer?'Agenda':'Inicio','dashboard'],
  ['clients',trainer?'Clientes':'Socios','clients'],
  ['workouts','Mis entrenos','workouts'],
  ['tarifas','Planes','products'],
  ['facturacion','Facturación','billing'],
  ...(!trainer?[['team','Equipo','team']]:[]),
  ...(platformRole==='platform_admin'&&!delegation?[['platform','Administración Repera','admin']]:[])
 ]:[['overview','Inicio','dashboard'],...(platformRole==='platform_admin'?[['platform','Administración Repera','admin']]:[])];
 if(activeTab==='settings'){/* permitido vía identidad */}
 else if(!tabs.some(t=>t[0]===activeTab))activeTab='overview';
 scrubFlashDupes(root);
 root.querySelectorAll('.business-navigation, .pt-nav-row').forEach(el=>el.remove());
 const nav=document.createElement('nav');nav.className='business-navigation is-pro';nav.setAttribute('aria-label','Menú profesional');
 nav.innerHTML=tabs.map(([id,label,icon])=>`<button type="button" data-workspace="${id}" aria-current="${activeTab===id?'page':'false'}">${navIcon(icon)}${escapeHTML(label)}</button>`).join('');
 if(visibleOrganizations.length>1){
  const picker=document.createElement('label');picker.className='connected-field pt-nav-org-picker';
  picker.innerHTML=`<span class="sr-only">Organización activa</span><select id="workspace-org-select"><option value="">Selecciona un negocio</option>${visibleOrganizations.map(o=>`<option value="${escapeHTML(o.id)}" ${o.id===selectedOrg?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select>`;
  nav.append(picker);
 }
 // Fuera del menú (misma altura, a la derecha): mes / Invitar / Nueva plantilla.
 const orgKind=org?.kind;
 const isTrainerNav=orgKind==='personal_trainer';
 let navChrome='';
 if(org&&activeTab==='overview'){
  navChrome=agendaMonthChromeHTML({calendarMonth,agendaDay,agendaView,variant:isTrainerNav?'trainer':'gym'});
 }else if(org&&activeTab==='clients'&&!selectedClientId&&!clientEditorOpen&&manager){
  navChrome=`<button type="button" class="connected-primary pt-nav-action" data-action="open-invite-modal" ${busy?'disabled':''}>${isTrainerNav?'Invitar cliente':'Invitar socio'}</button>`;
 }else if(org&&activeTab==='workouts'&&manager){
  navChrome=`<button type="button" class="connected-primary pt-nav-action" data-action="new-library-template" ${busy?'disabled':''}>+ Nueva plantilla</button>`;
 }
 const navRow=document.createElement('div');
 navRow.className='pt-nav-row';
 navRow.append(nav);
 if(navChrome){
  const rail=document.createElement('div');
  rail.className='pt-nav-chrome-rail';
  rail.innerHTML=navChrome;
  navRow.append(rail);
 }
 root.querySelector('.connected-heading')?.insertAdjacentElement('afterend',navRow);
 if(!org){
  if(platformRole==='platform_admin'){
   const sec=document.createElement('section');sec.dataset.workspaceSection='platform';sec.className='connected-card';
   sec.innerHTML=`<h2>Administración Repera</h2><p>Consulta de negocios, sin acceso a historial privado.</p>${platformOrgs.map(o=>`<article class="connected-org"><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(o.kind)} · ${Number(o.client_count||0)} clientes</small></article>`).join('')||'<p>Sin organizaciones registradas.</p>'}`;
   sec.insertAdjacentHTML('beforeend',renderPlanAdministration(planCatalog));root.append(sec);root.querySelectorAll('[data-workspace-section]').forEach(el=>el.style.display=el.dataset.workspaceSection===activeTab?'':'none');
  }
  return;
 }
 // Identidad clicable → Ajustes (PT y gym); una sola línea de rol.
 const roleOneLine=trainer?'Entrenador personal':(org.kind==='gym'||org.kind==='sports_center'?'Gimnasio':kindLabel[org.kind]||'Negocio');
 const heading=root.querySelector('.connected-heading');
 if(heading){
  const logoURL=org.avatar_url&&/^https:\/\//.test(org.avatar_url)?escapeHTML(org.avatar_url):'';
  const avatar=logoURL?`<img src="${logoURL}" alt="">`:`<span>${escapeHTML((org.name||'?').slice(0,1).toUpperCase())}</span>`;
  const exit=delegation
   ?`<button type="button" class="business-delegate-exit" data-admin-action="exit-delegation" ${busy?'disabled':''}>Volver al admin</button>`
   :'';
  // Con modal abierta, el aviso va solo dentro del sheet.
  const modalOpen=Boolean(businessDialog||showInviteModal);
  const flash=(!modalOpen&&(error||notice))?flashChip('heading'):'';
  const reqN=(Array.isArray(enrollmentRequests)?enrollmentRequests:[]).filter(r=>!r.status||r.status==='pending').length;
  const gymHeaderActions=manager&&!trainer?`<button type="button" class="connected-secondary" data-action="open-invite-modal" ${busy?'disabled':''}>Invitar</button>
   <button type="button" class="pt-icon-btn pt-bell-btn" data-action="open-notifications" aria-label="Notificaciones" title="Notificaciones" ${busy?'disabled':''}>
    <span class="pt-bell-circle">${navIcon('notifications')}</span>
    ${reqN>0?`<span class="pt-badge pt-bell-badge" aria-label="${reqN} pendientes">${reqN>99?'99+':reqN}</span>`:''}
   </button>
   <button type="button" class="pt-icon-btn pt-power-btn" data-action="logout" aria-label="Cerrar sesión" title="Cerrar sesión" ${busy?'disabled':''}>
    <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.85" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2v10"/><path d="M6.3 6.3a8 8 0 1 0 11.4 0"/></svg>
   </button>`
   :`<button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button>`;
  heading.innerHTML=`<img class="pt-repera-mark" src="./favicon.png" width="36" height="36" alt="Repera">
  <button type="button" class="pt-identity" data-workspace="settings" aria-label="Abrir ajustes">
   <span class="pt-identity-avatar">${avatar}</span>
   <span class="pt-identity-text"><strong>${escapeHTML(org.name)}</strong><small>${escapeHTML(roleOneLine)}</small></span>
  </button>
  ${flash}
  <div class="pt-heading-actions">${exit}${gymHeaderActions}</div>`;
 }
 // Quitar TODO el HTML legacy del shell (Invitar/Programación/onboarding) antes de montar la app.
 root.querySelectorAll('[data-workspace-section], .connected-grid, .connected-next, .business-overlay, .pt-overlay, [data-trial-banner]')
  .forEach(el=>el.remove());
 const attach=(tab,html)=>{const node=document.createElement('div');node.dataset.workspaceSection=tab;node.innerHTML=html;root.append(node);};
 // Coach de clase/cita debe ser miembro real (FK). No inyectar admin de soporte.
 const coachOptions=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'&&['owner','admin','coach'].includes(m.role)).map(m=>({user_id:m.user_id,label:m.user_id===user.id?'Yo (mi cuenta)':'Profesional '+m.user_id.slice(0,8)}));
 attach('overview',renderBusinessHome({org,clients,occurrences,bookings,sessions:professionalSessions,templates,requests:enrollmentRequests,manager,calendarMonth,passes,groups,busy,agendaView,agendaDay,gymAssignments,coaches:coachOptions,details:classDetails,roomFilter:agendaRoom,expandedOccurrenceId,rooms:facilityRooms,operationSettings})
  +renderDayProgramPanel({manager,activityTypes,rooms:facilityRooms,settings:operationSettings,esc:escapeHTML,day:agendaDay||todayISO()}));
 if(clientEditorOpen){
  const cName=clients.find(c=>c.id===selectedClientId)?.name||'';
  attach('clients',renderClientWorkoutFullscreen({
   orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,
   clients:clients.filter(c=>!c.account_deleted_at),escapeHTML,busy,
   templateId:selectedTemplateId,sessionId:editingSessionId,clientId:selectedClientId||quickWorkoutClient||'',
   preferredDate:draftSessionMeta?.date||planningSelectedDay||agendaDay||todayISO(),seedPrescription,copyClientId:copyBrowseClientId,clientName:cName,
   draftTitle:draftSessionMeta?.title||'',draftInstructions:draftSessionMeta?.instructions||'',
  }));
 }else if(selectedGroupId&&!selectedClientId){
  attach('clients',renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,selectedGroup:selectedGroupId,coaches:coachOptions,manager}));
 }else{
  attach('clients',renderClient360({clients,selected:selectedClientId,passes,offers,bookings,occurrences,sessions:professionalSessions,notices,chatMessages,sharedHistory,attendance,passEvents,trainerActivityMonth,trainerActivityDay,manager,trainer,busy,seat,role:own.get(selectedOrg),clientSection,clientQuery,gymAssignments,agendaView,agendaDay,calendarMonth,invitations,orgId:selectedOrg,inviteShare:lastInviteShare,org,groups,groupMembers,details:classDetails,coaches:coachOptions}));
 }
 attach('workouts',renderTrainerWorkoutsLibrary({templates,templateId:libraryTemplateId,busy,manager,audience:trainer?'trainer':'gym'}));
 attach('tarifas',trainer
  ?renderTrainerPassPanel({clients,passes,offers,seat,manager})
  :renderGymPassPanel({clients,passes,offers,manager}));
 attach('facturacion',renderBillingDashboard({clients,passes,offers,attendance,manager}));
 const members=coachOptions;
 if(!trainer){
  attach('team',renderTeamWorkspace({org,memberships,invitations,manager,busy,userId:user.id}));
 }
 attach('platform',`<section class="connected-card"><h2>Administración Repera</h2><p>Resumen de organizaciones de la plataforma. No permite acceder al historial privado de los deportistas ni suplantar cuentas.</p><div class="table-scroll"><table><thead><tr><th>Organización</th><th>Tipo</th><th>Clientes</th><th>Prueba finaliza</th></tr></thead><tbody>${platformOrgs.map(o=>`<tr><td>${escapeHTML(o.name)}</td><td>${escapeHTML(o.kind)}</td><td>${Number(o.client_count||0)}</td><td>${escapeHTML(o.trial_ends_at?.slice(0,10)||'—')}</td></tr>`).join('')||'<tr><td colspan="4">No hay organizaciones</td></tr>'}</tbody></table></div></section>${platformRole==='platform_admin'?renderPlanAdministration(planCatalog):''}`);
 attach('settings',renderSettingsWorkspace({org,kind,trainer,manager,seat}));
 const trial=trialStatus();
 if(!trial.active&&!delegation&&activeTab!=='settings'){
  const banner=document.createElement('div');banner.className='connected-error';banner.dataset.trialBanner='';
  banner.innerHTML='<strong>Prueba finalizada.</strong> Elige un plan en Ajustes (toca tu nombre arriba). Los pagos todavía no están disponibles.';
  nav.insertAdjacentElement('afterend',banner);
 }
 root.querySelectorAll('[data-workspace-section]').forEach(el=>{el.style.display=el.dataset.workspaceSection===activeTab?'':'none';});
 root.querySelectorAll('[data-settings-panel]').forEach(el=>el.style.display=el.dataset.settingsPanel===settingsSection?'':'none');
 // Diálogos y sheets compartidos (PT y gym).
 if(trainer)root.insertAdjacentHTML('beforeend',trainerDialogMarkup({manager,members}));
 if(showInviteModal)root.insertAdjacentHTML('beforeend',renderInviteModal({
  gym:!trainer,draft:inviteDraft,emailError:inviteEmailError,offers,busy,trainer,
 }));
 const invitePassForm=root.querySelector('[data-invite-pass-form]');
 if(invitePassForm){
  const syncInvitePass=()=>{
   const mode=invitePassForm.querySelector('input[name="passMode"]:checked')?.value||'none';
   invitePassForm.querySelectorAll('[data-invite-pass-panel]').forEach(el=>{
    el.hidden=el.dataset.invitePassPanel!==mode;
   });
   const confirm=invitePassForm.querySelector('input[name="confirmed"]');
   if(confirm)confirm.required=mode==='paid';
  };
  invitePassForm.querySelectorAll('[data-invite-pass-mode]').forEach(el=>{
   el.addEventListener('change',syncInvitePass);
  });
  syncInvitePass();
 }
 if(businessDialog==='gym-assignment'){
  const g=gymAssignments.find(x=>x.id===selectedClassId);
  if(g)root.insertAdjacentHTML('beforeend',renderGymAssignmentDialog(g));
 }
 if(businessDialog==='notifications'||businessDialog==='requests'||businessDialog==='broadcast'){
  const waiting=(Array.isArray(enrollmentRequests)?enrollmentRequests:[])
   .filter(r=>!r.status||r.status==='pending');
  root.insertAdjacentHTML('beforeend',renderNotificationsDrawer({
   waiting,clients,occurrences,groups,manager,busy,
   focus:businessDialog==='broadcast'?'broadcast':'requests',
  }));
 }
 if(businessDialog==='assign-pass'&&selectedClientId){
  const c=clients.find(x=>x.id===selectedClientId);
  if(c)root.insertAdjacentHTML('beforeend',renderAssignPassModal({
   client:c,offers,manager,busy,trainer,mode:dialogDay==='renew'?'renew':'new',
  }));
 }
 if(businessDialog==='new-group'){
  root.insertAdjacentHTML('beforeend',renderNewGroupModal({busy}));
 }
 if(businessDialog==='new-class'){
  root.insertAdjacentHTML('beforeend',renderNewClassModal({
   coaches:members,busy,day:dialogDay,
   templates,templateId:assignTemplateId,
   seedPrescription,
   rooms:operationSettings?.use_rooms?facilityRooms:[],
   activityTypes,
  }));
 }
 if(businessDialog==='new-client-workout'){
  const cwId=quickWorkoutClient||selectedClientId||'';
  const cw=clients.find(c=>c.id===cwId)||null;
  root.insertAdjacentHTML('beforeend',renderNewClientWorkoutModal({
   client:cw,clients,day:planningSelectedDay||agendaDay||dialogDay||todayISO(),
   busy,templates,templateId:assignTemplateId||selectedTemplateId||'',seedPrescription,
  }));
 }
 if(businessDialog==='edit-class'&&selectedClassId){
  const occ=occurrences.find(o=>o.id===selectedClassId&&o.kind==='class');
  const det=classDetails.find(d=>d.occurrence_id===selectedClassId)||{};
  if(occ){
   // Al final del workspace (fuera de secciones ocultas) para que el sheet sea visible.
   root.insertAdjacentHTML('beforeend',renderEditClassModal({
    occurrence:occ,
    detail:{
     ...det,
     training_title:draftSessionMeta?.title||det.training_title,
     training_instructions:draftSessionMeta?.instructions??det.training_instructions,
    },
    coaches:members,busy,occurrences,
    templates,templateId:assignTemplateId,
    seedPrescription:seedPrescription||det.prescription||null,
    assignScope,
   }));
  }else{
   businessDialog='';
   error='No se pudo abrir el editor de la clase.';
  }
 }
 if(businessDialog==='enroll-class'&&selectedClassId){
  const occ=occurrences.find(o=>o.id===selectedClassId);
  if(occ)root.insertAdjacentHTML('beforeend',renderEnrollClassModal({occurrence:occ,clients,passes,busy}));
 }
 if(businessDialog==='publish-class-plan'&&selectedClassId){
  const occ=occurrences.find(o=>o.id===selectedClassId);
  const det=classDetails.find(d=>d.occurrence_id===selectedClassId)||{};
  const linkedSession=professionalSessions.find(s=>s.source_occurrence_id===selectedClassId&&s.prescription);
  const tpl=templates.find(t=>t.id===assignTemplateId);
  // Preferir borrador en memoria (edición en curso / error de guardado) sobre plantilla o detalle.
  const classSeed=seedPrescription||tpl?.prescription||det.prescription||linkedSession?.prescription||null;
  if(occ)root.insertAdjacentHTML('beforeend',renderPublishClassPlanModal({
   occurrence:occ,
   detail:{
    ...det,
    training_title:draftSessionMeta?.title||det.training_title,
    training_instructions:draftSessionMeta?.instructions??det.training_instructions,
   },
   occurrences,
   details:classDetails,
   busy,
   templates,
   templateId:assignTemplateId,
   seedPrescription:classSeed,
   assignScope,
  }));
 }
 if(businessDialog==='assign-class-training'){
  const day=assignClassDay||agendaDay||todayISO();
  const dayOcc=occurrences.filter(o=>
   o.kind==='class'&&o.status==='active'
   &&new Date(o.starts_at).toLocaleDateString('sv-SE')===day
  );
  const tpl=templates.find(t=>t.id===assignTemplateId);
  root.insertAdjacentHTML('beforeend',renderAssignClassTrainingModal({
   day,
   occurrences,
   details:classDetails,
   templates,
   preselectedIds:assignPreselectedIds.length?assignPreselectedIds:dayOcc.map(o=>o.id),
   onlyWithoutPlan:assignOnlyWithout,
   busy,
   seedPrescription:seedPrescription||tpl?.prescription||null,
   titleSeed:draftSessionMeta?.title||tpl?.name||'',
   instructionsSeed:draftSessionMeta?.instructions||'',
   templateId:assignTemplateId,
   lockSelection:false,
   assignScope,
  }));
 }
 if(businessDialog==='create-plan'||businessDialog==='edit-plan'){
  const offer=businessDialog==='edit-plan'?offers.find(o=>o.id===selectedOfferId):null;
  root.insertAdjacentHTML('beforeend',renderPassOfferModal({
   busy,includeGymScope:!trainer,defaultKind:trainer?'appointment':'class',offer:offer||null,
  }));
 }
 // Aviso del modal: solo dentro del sheet (nunca también en cabecera).
 if((businessDialog||showInviteModal)&&(error||notice)){
  const sheetBody=root.querySelector('.pt-overlay .pt-sheet-body, .pt-overlay .business-dialog-scroll, .pt-overlay .pt-notif-scroll');
  if(sheetBody){
   sheetBody.querySelectorAll('[data-dialog-flash]').forEach(el=>el.remove());
   sheetBody.insertAdjacentHTML('afterbegin',flashChip('dialog'));
  }
 }
 // Restos sueltos bajo el menú (no tocar el banner de prueba).
 root.querySelectorAll('.business-navigation ~ .connected-notice, .business-navigation ~ .connected-error:not([data-trial-banner]), .business-navigation ~ [data-workspace-flash]').forEach(el=>el.remove());
 if(businessDialog==='bulk'){const bulk=root.querySelector('form[data-connected="bulk-training"]');if(bulk)refreshBulkPlanPreview(bulk);}
 const classCreate=root.querySelector('form[data-class-week-create]');
 if(classCreate){
  const bindWeekSlotInputs=scope=>{
   scope.querySelectorAll('.pt-week-slot input').forEach(inp=>{
    inp.addEventListener('change',()=>{
     const slot=inp.closest('.pt-week-slot');
     slot?.classList.toggle('is-on',inp.checked);
     const color=classCreate.querySelector('input[name="color"]:checked')?.value||'#22834d';
     slot?.style.setProperty('--slot-color',color);
    });
   });
  };
  const syncSchedulePanels=()=>{
   const mode=classCreate.querySelector('[data-class-schedule-mode]')?.value||'unique';
   classCreate.querySelectorAll('[data-class-panel]').forEach(panel=>{
    const on=panel.getAttribute('data-class-panel')===mode;
    panel.hidden=!on;
    panel.querySelectorAll('input,select,textarea').forEach(el=>{
     if(el.name==='untilMode'||el.name==='untilDate'||el.name==='slot')return;
     if(on)el.removeAttribute('disabled');
     else el.setAttribute('disabled','disabled');
    });
   });
   // Slots / until solo aplican en repetitiva.
   classCreate.querySelectorAll('input[name="slot"], input[name="untilMode"], input[name="untilDate"]').forEach(el=>{
    if(mode==='weekly')el.removeAttribute('disabled');
    else el.setAttribute('disabled','disabled');
   });
  };
  const rebuildWeekGrid=()=>{
   const host=classCreate.querySelector('[data-week-slot-host]');
   if(!host)return;
   const color=classCreate.querySelector('input[name="color"]:checked')?.value||'#22834d';
   const duration=Number(classCreate.querySelector('[data-week-duration]')?.value||60);
   const selected=new Set([...classCreate.querySelectorAll('input[name="slot"]:checked')].map(i=>i.value));
   const label=host.querySelector(':scope > span');
   host.innerHTML='';
   if(label)host.append(label);
   else host.insertAdjacentHTML('afterbegin','<span>Días y franjas</span>');
   host.insertAdjacentHTML('beforeend',weekSlotGrid(selected,{durationMin:duration,color}));
   bindWeekSlotInputs(host);
   syncSchedulePanels();
  };
  bindWeekSlotInputs(classCreate);
  syncSchedulePanels();
  classCreate.querySelector('[data-class-schedule-mode]')?.addEventListener('change',syncSchedulePanels);
  classCreate.querySelector('[data-week-duration]')?.addEventListener('change',rebuildWeekGrid);
  classCreate.querySelectorAll('input[name="color"]').forEach(el=>{
   el.addEventListener('change',()=>{
    const color=classCreate.querySelector('input[name="color"]:checked')?.value||'#22834d';
    classCreate.querySelectorAll('.pt-week-slot, [data-week-slots]').forEach(node=>{
     node.style.setProperty('--slot-color',color);
    });
   });
  });
 }
 const roomSel=root.querySelector('select[data-action="agenda-room-filter"]');
 if(roomSel){
  roomSel.addEventListener('change',()=>{agendaRoom=roomSel.value||'';render();});
 }
 const planForm=root.querySelector('form[data-pass-offer-form]');
 const planPreview=root.querySelector('.pt-plan-preview');
 if(planForm&&planPreview){
  const syncPreview=()=>{
   const billing=planForm.querySelector('[name="billing"]:not([type="hidden"])')?.value
    ||planForm.querySelector('input[name="billing"]')?.value||'session_pack';
   const name=planForm.querySelector('[name="name"]')?.value?.trim()||'Vista previa';
   let price=0,detail='Completa el formulario';
   if(billing==='session_pack'){
    price=Number(planForm.querySelector('[name="price"]')?.value||0);
    detail=`${planForm.querySelector('[name="credits"]')?.value||'?'} sesiones · ${planForm.querySelector('[name="validityDays"]')?.value||'?'} días`;
   }else if(billing==='monthly'){
    price=Number(planForm.querySelector('[name="priceMonthly"]')?.value||0);
    detail=`Mensual · ${planForm.querySelector('[name="validityDaysMonthly"]')?.value||'?'} días`;
   }else if(billing==='unlimited'){
    price=Number(planForm.querySelector('[name="priceUnlimited"]')?.value||0);
    detail=`Ilimitado · ${planForm.querySelector('[name="validityDaysUnlimited"]')?.value||'?'} días`;
   }else if(billing==='time_slot'){
    price=Number(planForm.querySelector('[name="priceSlot"]')?.value||0);
    detail=`Franja · ${planForm.querySelector('[name="validityDaysSlot"]')?.value||'?'} días`;
   }
   const money=new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(price||0);
   planPreview.querySelector('h3').textContent=name;
   planPreview.querySelector('strong').innerHTML=`${money}<small> · cobro externo</small>`;
   planPreview.querySelector('p').textContent=detail;
  };
  planForm.addEventListener('input',syncPreview);
  planForm.addEventListener('change',syncPreview);
  syncPreview();
 }
 syncBillingFields(root);
}
function syncQuickWorkoutForm(form){
 if(!form)return;
 const mode=form.querySelector('input[name="mode"]:checked')?.value||'day';
 const showMulti=mode==='weekly'||mode==='plan';
 form.querySelector('[data-quick-weekdays]')?.toggleAttribute('hidden',!showMulti);
 form.querySelector('[data-quick-weeks]')?.toggleAttribute('hidden',mode!=='weekly');
 form.querySelector('[data-quick-end]')?.toggleAttribute('hidden',mode!=='plan');
 const start=form.querySelector('[name="date"]')?.value||'';
 let end=form.querySelector('[name="end"]')?.value||start;
 const weeks=Number(form.querySelector('[name="weeks"]')?.value||4);
 if(mode==='weekly'&&start){
  const d=new Date(start+'T12:00:00');d.setDate(d.getDate()+(Math.min(Math.max(weeks,1),8)*7)-1);
  end=d.toLocaleDateString('sv-SE');
  const endInput=form.querySelector('[name="end"]');if(endInput)endInput.value=end;
 }
 const weekdays=[...form.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
 const n=countQuickWorkoutSessions({mode,start,end,weeks,weekdays});
 const preview=form.querySelector('[data-quick-preview]');
 if(preview){
  if(mode==='day')preview.textContent=`1 sesión el ${start||'—'}`;
  else if(mode==='weekly')preview.textContent=n?`${n} sesiones · ${weeks} semana${weeks===1?'':'s'} · días marcados`:'Marca al menos un día de la semana';
  else preview.textContent=n?`${n} sesiones del ${start} al ${end}`:'Elige rango y días de entreno';
 }
}
function syncBillingFields(root=app){
 root.querySelectorAll('form[data-connected="create-pass-offer"],form[data-connected="update-pass-offer"]').forEach(form=>{
  const billing=form.querySelector('[data-billing-select]')?.value||'session_pack';
  form.querySelectorAll('[data-billing-fields]').forEach(block=>{
   const show=block.dataset.billingFields===billing;
   block.hidden=!show;
   block.toggleAttribute('inert',!show);
   block.querySelectorAll('input,select,textarea').forEach(inp=>{
    inp.disabled=!show;
    if(!show){inp.required=false;return;}
    const need={
     credits:billing==='session_pack'&&inp.name==='credits',
     validityDays:billing==='session_pack'&&inp.name==='validityDays',
     price:billing==='session_pack'&&inp.name==='price',
     validityDaysMonthly:billing==='monthly'&&inp.name==='validityDaysMonthly',
     priceMonthly:billing==='monthly'&&inp.name==='priceMonthly',
     validityDaysUnlimited:billing==='unlimited'&&inp.name==='validityDaysUnlimited',
     priceUnlimited:billing==='unlimited'&&inp.name==='priceUnlimited',
     validityDaysSlot:billing==='time_slot'&&inp.name==='validityDaysSlot',
     priceSlot:billing==='time_slot'&&inp.name==='priceSlot',
     slotStart:billing==='time_slot'&&inp.name==='slotStart',
     slotEnd:billing==='time_slot'&&inp.name==='slotEnd',
    };
    inp.required=!!need[inp.name];
   });
  });
  const hints={
   session_pack:'Bono: Nº de sesiones y validez. Cobro fuera de Repera.',
   monthly:'Mensual: solo periodo y precio. Sin cupo de sesiones.',
   unlimited:'Ilimitado: validez del acceso y precio. Sin límite práctico de sesiones.',
   time_slot:'Franja: el cliente solo puede reservar citas (o gym) que empiecen en esos días y horas.',
  };
  const hint=form.querySelector('[data-billing-hint]');
  if(hint)hint.textContent=hints[billing]||hints.session_pack;
 });
}
function renderTeamWorkspace({org,memberships=[],invitations=[],manager=false,busy=false,userId=''}){
 const staff=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'
  &&['owner','admin','coach','reception'].includes(m.role));
 const pending=invitations.filter(i=>i.organization_id===org.id&&!i.accepted_at&&!i.cancelled_at
  &&new Date(i.expires_at).getTime()>Date.now()
  &&['admin','coach','reception'].includes(i.invited_role));
 const roleName={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción'};
 const roleOptions=[['coach','Entrenador'],['reception','Recepción'],['admin','Administrador']];
 return `<div class="pt-team-workspace pt-team-split">
  <section class="connected-card pt-team-col">
   <div class="business-panel-head"><div><h2>Equipo</h2>
    <p>Roles y acceso del personal.</p></div>
    ${manager?`<button type="button" class="connected-primary" data-action="open-team-invite">Invitar</button>`:''}</div>
   <div class="pt-team-list">${staff.map(m=>{
    const self=m.user_id===userId;
    const label=self?'Tú':('Profesional '+escapeHTML((m.user_id||'').slice(0,8)));
    return `<article class="pt-team-card">
     <div class="pt-team-card-main"><strong>${label}</strong>
      <small>${escapeHTML(roleName[m.role]||m.role)}</small></div>
     ${manager&&!self&&m.role!=='owner'?`<form data-connected="manage-member" class="pt-team-edit">
      <input type="hidden" name="user" value="${escapeHTML(m.user_id)}">
      <input type="hidden" name="op" value="set_role">
      <label class="connected-field">Rol<select name="role">${roleOptions.map(([v,t])=>`<option value="${v}" ${m.role===v?'selected':''}>${t}</option>`).join('')}</select></label>
      <button type="submit" class="connected-secondary" ${busy?'disabled':''}>Guardar</button>
      <button type="button" class="connected-secondary" data-action="revoke-member" data-id="${escapeHTML(m.user_id)}" ${busy?'disabled':''}>Quitar</button>
     </form>`:(self||m.role==='owner'?'<p class="connected-hint">'+escapeHTML(m.role==='owner'?'Propietario del centro.':'Tu cuenta.')+'</p>':'')}
    </article>`;
   }).join('')||'<p class="business-empty">Todavía no hay miembros de equipo.</p>'}</div>
  </section>
  ${manager?`<section class="connected-card pt-team-col" id="team-invite-panel"><h2>Invitar al equipo</h2>
   <form data-connected="invite" class="business-form">
    <label class="connected-field">Correo del invitado<input name="email" type="email" required autocomplete="email"></label>
    <label class="connected-field">Perfil<select name="role">
     <option value="coach">Entrenador</option>
     <option value="reception">Recepción</option>
     <option value="admin">Administrador</option>
    </select></label>
    <button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button>
   </form>
   ${pending.length?`<h3>Pendientes</h3>${pending.map(i=>`<article class="business-line pt-team-pending"><div><strong>${escapeHTML(i.email||'')}</strong>
    <small>${escapeHTML(roleName[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div>
    <button type="button" class="connected-secondary" data-action="cancel-team-invite" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Anular</button>
   </article>`).join('')}`:''}
  </section>`:'<section class="connected-card pt-team-col"><p class="connected-hint">Solo propietarios y administradores gestionan el equipo.</p></section>'}
 </div>`;
}
function renderSettingsWorkspace({org,kind,trainer,manager,seat}){
 // Perfil sin desplegable de actividad (fija) ni bloque legal (va a su pestaña).
 let profileForm=renderOrganizationFields({kind,values:org,legal:{}});
 profileForm=profileForm.replace(/<div class="business-onboarding-group"><div class="business-onboarding-heading"><h3>Datos legales[\s\S]*?<\/div><\/div>/,'');
 profileForm=profileForm.replace(/<label class="connected-field[^"]*">Actividad<select name="kind">[\s\S]*?<\/select><\/label>/,
  `<input type="hidden" name="kind" value="${escapeHTML(kind)}">`);
 return `<div class="pt-settings">
  <nav class="business-settings-navigation pt-settings-nav" aria-label="Ajustes">
   <button data-settings-section="profile" type="button" aria-current="${settingsSection==='profile'?'page':'false'}">Perfil</button>
   <button data-settings-section="operation" type="button" aria-current="${settingsSection==='operation'?'page':'false'}">Operación</button>
   <button data-settings-section="services" type="button" aria-current="${settingsSection==='services'?'page':'false'}">Servicios</button>
   <button data-settings-section="legal" type="button" aria-current="${settingsSection==='legal'?'page':'false'}">Datos legales</button>
   <button data-settings-section="plan" type="button" aria-current="${settingsSection==='plan'?'page':'false'}">Plan</button>
  </nav>
  <section data-settings-panel="profile" class="connected-card pt-settings-card">
   <h2>Perfil profesional</h2>
   <p>Avatar, nombre y contacto visibles para tus clientes.</p>
   <form data-connected="settings" class="business-onboarding-form pt-profile-form">
    ${profileForm}
    <label class="connected-field">Zona horaria<input name="timezone" value="${escapeHTML(org.timezone||'Europe/Madrid')}" maxlength="80"></label>
    ${manager?'<button class="connected-primary business-form-submit" type="submit">Guardar perfil</button>':''}
   </form>
  </section>
  ${renderOperationSettings({org,settings:operationSettings,rooms:facilityRooms,activityTypes,manager,busy,esc:escapeHTML})}
  ${renderServicesSettings({org,manager,busy,trainer,draft:whatsappDraft})}
  <section data-settings-panel="legal" class="connected-card pt-settings-card">
   <h2>Datos legales</h2>
   <p>Solo propietarios y administradores. No se muestran en el directorio público.</p>
   <form data-connected="settings" class="business-onboarding-form">
    <input type="hidden" name="name" value="${escapeHTML(org.name||'')}">
    <input type="hidden" name="kind" value="${escapeHTML(kind)}">
    <label class="connected-field">Razón social<input name="legal_name" value="${escapeHTML(legalProfile?.legal_name||'')}" maxlength="180"></label>
    <label class="connected-field">NIF / CIF<input name="tax_id" value="${escapeHTML(legalProfile?.tax_id||'')}" maxlength="40"></label>
    <label class="connected-field">Domicilio fiscal<input name="billing_address" value="${escapeHTML(legalProfile?.billing_address||'')}" maxlength="300"></label>
    <label class="connected-field">Email facturación<input name="billing_email" type="email" value="${escapeHTML(legalProfile?.billing_email||'')}" maxlength="180"></label>
    ${manager?'<button class="connected-primary" type="submit">Guardar datos legales</button>':''}
   </form>
  </section>
  <section data-settings-panel="plan" class="pt-settings-card pt-plan-wrap">${renderSubscriptions(org)}</section>
 </div>`;
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
 if(!user){
  const title={login:invitationLink?'Tu invitación':'Hola de nuevo',join:'Cuenta de deportista',register:'Empieza tu espacio',recover:'Recuperar acceso',password:'Nueva contraseña'}[view];
  const intro={login:invitationLink?'Acepta la relación con tu centro o entrenador.':'Entra a tu agenda, clientes y mensajería.',join:'Después de verificar el correo podrás aceptar la invitación.',register:'Agenda, clientes y tarifas en un solo sitio. 7 días de prueba, sin tarjeta.',recover:'Te enviaremos un enlace para restablecer la contraseña.',password:'Elige una contraseña de al menos 8 caracteres.'}[view];
  const form=view==='login'
   ?`${field('Correo','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='join'
   ?`${field('Correo','email','email')}${field('Contraseña (mín. 8)','password','password','minlength="8"')}<p class="connected-hint">No crea un negocio: solo tu cuenta de deportista.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Crear cuenta</button>`
   :view==='register'
   ?`${field('Correo','email','email')}${field('Contraseña (mín. 8)','password','password','minlength="8"')}<label class="connected-field">Soy<select name="businessKind" required><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option></select></label>${field('Nombre comercial','businessName','text','minlength="2" maxlength="120"')}<p class="connected-hint">Prueba 7 días. Los cobros en plataforma aún no están activos.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Crear espacio</button>`
   :view==='recover'
   ?`${field('Correo','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Guardar</button>`;
  app.innerHTML=`<div class="connected-page"><main class="connected-auth"><div class="connected-card"><img class="pt-repera-mark auth" src="./favicon.png" width="44" height="44" alt="Repera"><h1>${title}</h1><p class="connected-intro">${intro}</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver</button>':''}${view==='login'?`${invitationLink?'<button type="button" data-view="join">Soy nuevo</button>':'<button type="button" data-view="register">Crear espacio</button>'}<button type="button" data-view="recover">Olvidé la contraseña</button>`:''}</div></div></main></div>`;
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
   <section class="connected-card">
   <h1>Invitaciones</h1><p>Acepta con tu correo verificado. Tus entrenos privados no se comparten solos.</p>${message()}
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
 const shellKind=organizations.find(o=>o.id===selectedOrg)?.kind;
 const shellClass=[
  'connected-page',
  delegation?'is-delegated':'',
  shellKind==='personal_trainer'?'is-pt-app':'',
  shellKind==='gym'||shellKind==='sports_center'?'is-gym-app':'',
 ].filter(Boolean).join(' ');
 // Shell mínimo: enhanceWorkspace monta menú, pestañas y modales.
 // No incrustar Invitar/Programación legacy aquí (si enhanceWorkspace falla, tapaban Inicio).
 const bootstrap=!selectedOrg
  ?`<section data-workspace-section="overview" class="connected-grid connected-onboarding-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div></article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card">${renderOrganizationCreateForm(planCatalog,(()=>{try{return JSON.parse(sessionStorage.getItem(PENDING_REGISTRATION_KEY)||'null')||{};}catch{return {};}})())}</div></section>`
  :'';
 app.innerHTML=`<div class="${shellClass}"><main class="connected-workspace"><div class="connected-heading"><img class="pt-repera-mark" src="./favicon.png" width="36" height="36" alt="Repera"><div><h1>Tu espacio</h1><p>${escapeHTML(user.email||'Cuenta Repera')}${platformRole==='platform_admin'?' · Admin Repera':''}</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Salir</button></div>${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}${bootstrap}</main></div>`;
 try{enhanceWorkspace(own);}
 catch(e){
  console.error('enhanceWorkspace',e);
  error=error||('Error de interfaz: '+(e.message||'recarga la página'));
  const root=app.querySelector('.connected-workspace');
  if(root&&!root.querySelector('[data-workspace-section="overview"]')){
   root.insertAdjacentHTML('beforeend',`<section data-workspace-section="overview" class="connected-card"><p class="connected-error">${escapeHTML(error)}</p><button type="button" class="connected-secondary" data-action="dismiss-flash">Reintentar</button></section>`);
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
async function soft(label,promise,fallback){
 try{return await promise;}
 catch(e){
  if(e.status===401)throw e;
  console.warn('[repera]',label,e.message||e);
  return fallback;
 }
}
async function loadSelectedOrg(){
 if(!selectedOrg){clients=[];occurrences=[];passes=[];offers=[];attendance=[];bookings=[];passEvents=[];professionalSessions=[];templates=[];trialRows=[];classDetails=[];groups=[];groupMembers=[];notices=[];enrollmentRequests=[];legalProfile=null;operationSettings=null;facilityRooms=[];activityTypes=[];return;}
 const role=delegation?'admin':
  memberships.find(m=>m.organization_id===selectedOrg&&m.user_id===user?.id&&m.status==='active')?.role;
 const manager=['owner','admin'].includes(role);
 // Clientes primero y con error duro: tras aceptar una solicitud debe verse la ficha.
 clients=await auth.clients(selectedOrg,{basic:!manager});
 const rest=await Promise.all([
  soft('occurrences',auth.serviceOccurrences(selectedOrg),[]),
  soft('passes',auth.servicePasses(selectedOrg),[]),
  soft('offers',auth.servicePassOffers(selectedOrg),[]),
  soft('bookings',auth.serviceBookings(selectedOrg),[]),
  soft('sessions',auth.professionalSessions(selectedOrg),[]),
  soft('templates',['owner','admin','coach'].includes(role)?auth.workoutTemplates(selectedOrg):Promise.resolve([]),[]),
  soft('trial',auth.organizationTrial(selectedOrg),[]),
  soft('classDetails',auth.classDetails(selectedOrg),[]),
  soft('groups',['owner','admin','coach'].includes(role)?auth.groupList(selectedOrg):Promise.resolve([]),[]),
  soft('groupMembers',['owner','admin','coach'].includes(role)?auth.groupMembers(selectedOrg):Promise.resolve([]),[]),
  soft('notices',auth.clientNotifications(selectedOrg),[]),
  soft('passEvents',manager?auth.servicePassManagementEvents(selectedOrg):Promise.resolve([]),[]),
 ]);
 occurrences=rest[0];passes=rest[1];offers=rest[2];bookings=rest[3];professionalSessions=rest[4];
 templates=rest[5];trialRows=rest[6];classDetails=rest[7];groups=rest[8];groupMembers=rest[9];notices=rest[10];
 passEvents=rest[11];
 const avatars=await soft('avatars',auth.clientAvatars(selectedOrg),[]);
 const byId=new Map(avatars.map(a=>[a.client_id,a.avatar_url]));
 clients=clients.map(c=>({...c,avatar_url:byId.get(c.id)||c.avatar_url}));
 attendance=manager?await soft('attendance',auth.trainerAttendance(selectedOrg),[]):[];
 legalProfile=manager?await soft('legal',auth.legalProfile(selectedOrg),null):null;
 enrollmentRequests=manager?await soft('enrollments',auth.enrollmentRequests(selectedOrg),[]):[];
 const bundle=await soft('scheduleBundle',auth.getOrgScheduleBundle(selectedOrg),null);
 if(bundle&&typeof bundle==='object'){
  operationSettings=bundle.settings||null;
  facilityRooms=Array.isArray(bundle.rooms)?bundle.rooms:[];
  activityTypes=Array.isArray(bundle.activity_types)?bundle.activity_types:[];
 }else{
  operationSettings=await soft('opSettings',auth.getOrgOperationSettings(selectedOrg),null);
  facilityRooms=await soft('rooms',auth.listFacilityRooms(selectedOrg),[]);
  activityTypes=await soft('types',auth.listActivityTypes(selectedOrg),[]);
 }
 if(organizations.find(o=>o.id===selectedOrg)?.kind==='personal_trainer')await loadGymAssignments();
 else gymAssignments=[];
}
async function loadGymAssignments(){
 try{gymAssignments=await auth.listCoachAssignments();}
 catch{gymAssignments=[];}
}
async function reload(){
 // The platform role must be resolved independently of tenant membership RLS.
 // A broken business query must never hide the administrator's global console.
 const profile=await auth.myProfile();
 platformRole=profile?.role||null;
 adminAccount={...(profile||{}),avatar_url:profile?.avatar_url||user?.user_metadata?.avatar_url||null,
  display_name:profile?.display_name||user?.user_metadata?.name||''};
 planCatalog=await auth.businessPlans().catch(()=>planCatalog||[]);
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
  try{await auth.claimPlatformProvisioning();}catch(e){if(e.status===401)throw e;}
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
    activeTab='clients';clientEditorOpen=true;clientSection='training';adminSelectedAthlete='';adminAthleteDetail=null;
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
    notice='';
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
   busy=true;error=notice='';
   try{
    await auth.platformAdminEndDelegation();
   }catch(e){
    // Si el RPC falla pero no hay delegación activa, igual volvemos al panel global.
    console.warn('[repera] end-delegation',e.message||e);
   }
   try{
    delegation=null;selectedOrg=null;activeTab='overview';
    adminTab='centers';adminSelectedOrg='';adminCenterDetail=null;
    await reload();
    if(delegation){
     error='No se pudo cerrar la delegación. Inténtalo de nuevo.';
    }else{
     notice='Has vuelto a la administración global.';
    }
   }catch(e){error=e.message||'No se pudo volver a administración';}
   finally{busy=false;render();}
   return;
  }
 }
 if(handleEditorClick(event))return;
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 if(action==='dismiss-flash'){error=notice='';render();return;}
 const trainer=trainerActive();
 // Agenda Mes/Día ANTES que [data-view] de auth (antes el toggle Día pisaba view=login).
 // Pulsar un día del mes solo actualiza el rail derecho; la vista Día completa queda en el tab.
 if(action==='agenda-view'){
  const next=actionable.dataset.agendaView||actionable.dataset.view;
  agendaView=next==='day'?'day':'month';
  if(agendaView==='day'&&!/^\d{4}-\d{2}-\d{2}$/.test(agendaDay))agendaDay=todayISO();
  if(agendaView==='day'){
   if(!/^\d{4}-\d{2}-\d{2}$/.test(agendaDay))agendaDay=todayISO();
   calendarMonth=agendaDay.slice(0,7);
   trainerActivityDay=agendaDay;trainerActivityMonth=calendarMonth;
  }
  render();return;
 }
 if(action==='agenda-open-day'||action==='agenda-select-day'){
  agendaDay=actionable.dataset.day||todayISO();
  calendarMonth=agendaDay.slice(0,7);
  trainerActivityDay=agendaDay;trainerActivityMonth=calendarMonth;
  agendaView='month';
  render();return;
 }
 const tab=event.target.closest('[data-workspace]');if(tab){
  const next=tab.dataset.workspace;
  // Pulsar Clientes/Socios en el menú vuelve al listado (sin fila «Volver»).
  if(next==='clients'){selectedClientId=null;clientSection='training';clientEditorOpen=false;sharedHistory=[];}
  activeTab=next;businessDialog='';clientEditorOpen=false;setWorkspaceRoute();render();return;
 }
 const mode=event.target.closest('[data-view]');
 if(mode&&!mode.closest('[data-action]')&&['login','join','register','recover','password'].includes(mode.dataset.view)){
  view=mode.dataset.view;error=notice='';render();return;
 }
 const setting=event.target.closest('[data-settings-section]');
 if(setting){
  const s=setting.dataset.settingsSection;
  settingsSection=['plan','profile','legal','services','operation'].includes(s)?s:'profile';
  activeTab='settings';render();return;
 }
 if(action==='open-invite-modal'||action==='go-invite-client'||action==='focus-invite-form'){
  showInviteModal=true;inviteEmailError='';inviteDraft={name:'',email:'',phone:''};error='';notice='';
  render();return;
 }
 if(action==='close-invite-modal'){
  showInviteModal=false;inviteEmailError='';inviteDraft={name:'',email:'',phone:''};render();return;
 }
 if(action==='open-settings-services'){
  businessDialog='';showInviteModal=false;activeTab='settings';settingsSection='services';
  setWorkspaceRoute();render();return;
 }
 if(action==='disconnect-whatsapp'&&!busy){
  if(!confirm('¿Desconectar WhatsApp de este espacio?'))return;
  busy=true;error=notice='';render();
  try{
   const updated=await auth.disconnectOrgWhatsapp(selectedOrg);
   whatsappDraft=null;
   if(updated?.id){
    organizations=organizations.map(o=>o.id===updated.id?{...o,...updated,whatsapp_e164:null,whatsapp_connected_at:null}:o);
   }else{
    organizations=await soft('organizations',auth.organizations(),organizations);
   }
   settingsSection='services';activeTab='settings';
   notice='WhatsApp desconectado.';
  }catch(e){error=e.message||'No se pudo desconectar';}
  finally{busy=false;render();}
  return;
 }
 if(action==='show-invite-share'&&!busy){
  const id=actionable.dataset.id;
  const email=actionable.dataset.email||'';
  const inv=invitations.find(i=>i.id===id)||pendingAthleteInvite({invitations,orgId:selectedOrg,email});
  if(!inv){error='Sin invitación pendiente';render();return;}
  lastInviteShare={invitationId:inv.id,email:inv.email||email,sent:false,reason:''};
  const client=clients.find(c=>String(c.email||'').toLowerCase()===String(inv.email||email).toLowerCase());
  selectedClientId=client?.id||selectedClientId;
  clientSection='data';activeTab='clients';businessDialog='';showInviteModal=false;render();return;
 }
 if(action==='open-assign-pass'){
  selectedClientId=actionable.dataset.id||selectedClientId;
  clientSection='passes';activeTab='clients';
  dialogDay=actionable.dataset.mode==='renew'?'renew':'new';
  businessDialog='assign-pass';render();return;
 }
 if(action==='finalize-pass'&&!busy){
  if(!confirm('¿Finalizar este bono sin renovar? Quedará cancelado y no se podrá usar.'))return;
  busy=true;render();
  try{
   await auth.finalizeServicePass(actionable.dataset.id);
   if(actionable.dataset.client){selectedClientId=actionable.dataset.client;clientSection='passes';}
   await loadSelectedOrg();notice='Bono finalizado. No se ha renovado.';
  }catch(e){error=e.message||'No se pudo finalizar el bono';}
  finally{busy=false;render();}
  return;
 }
 if(action==='open-new-group-modal'){businessDialog='new-group';render();return;}
 if(action==='open-create-plan-modal'){
  selectedOfferId='';businessDialog='create-plan';error=notice='';render();return;
 }
 if(action==='open-edit-plan-modal'){
  selectedOfferId=actionable.dataset.id||'';
  if(!offers.some(o=>o.id===selectedOfferId))return;
  businessDialog='edit-plan';error=notice='';render();return;
 }
 if(action==='open-new-class-modal'){
  dialogDay=actionable.dataset.day||'';
  assignTemplateId='';
  assignScope='one';
  seedPrescription=null;
  draftSessionMeta=null;
  businessDialog='new-class';render();return;
 }
 if(action==='open-edit-class-modal'){
  const id=String(actionable.dataset.id||'').trim();
  const o=occurrences.find(x=>x.id===id&&x.kind==='class');
  if(!o){
   // Suele pasar si el clic era un fan-out de entreno (sesión), no la clase.
   error='Esa fila no es una clase del calendario. Abre la clase (Detalle) y pulsa Editar clase.';
   notice='';render();return;
  }
  selectedClassId=o.id;
  classEditorId=null;
  clientEditorOpen=false;
  expandedOccurrenceId=o.id;
  activeTab='overview';
  assignTemplateId='';
  assignScope='one';
  const det=classDetails.find(d=>d.occurrence_id===o.id)||{};
  seedPrescription=det.prescription||null;
  draftSessionMeta={
   title:det.training_title||'',
   instructions:det.training_instructions||'',
  };
  businessDialog='edit-class';
  agendaDay=new Date(o.starts_at).toLocaleDateString('sv-SE');
  render();return;
 }
 if(action==='open-enroll-class'){
  selectedClassId=actionable.dataset.id||'';
  expandedOccurrenceId=selectedClassId;
  businessDialog='enroll-class';render();return;
 }
 if(action==='enroll-client-in-class'&&!busy){
  const occurrenceId=actionable.dataset.id||'';
  const clientId=actionable.dataset.client||selectedClientId||'';
  const occ=occurrences.find(o=>o.id===occurrenceId);
  if(!occ||!clientId)return;
  const pass=passes.find(p=>p.client_id===clientId&&p.status==='active'&&p.kind===occ.kind&&p.remaining_credits>0&&Date.parse(p.valid_until)>Date.now());
  if(!pass){error='Este socio no tiene un plan activo con crédito para esa clase.';render();return;}
  busy=true;error='';render();
  try{
   await auth.enrollManagedClient({occurrenceId,clientId,passId:pass.id});
   await loadSelectedOrg();
   notice='Socio apuntado (igual que desde la app).';
  }catch(e){error=friendlyPassBookError(e.message)||'No se pudo apuntar';}
  finally{busy=false;render();}
  return;
 }
 if(action==='toggle-occurrence-detail'){
  const id=actionable.dataset.id||'';
  expandedOccurrenceId=expandedOccurrenceId===id?'':id;
  selectedClassId=expandedOccurrenceId||selectedClassId;
  const o=occurrences.find(x=>x.id===id);
  if(o)agendaDay=new Date(o.starts_at).toLocaleDateString('sv-SE');
  render();return;
 }
 if(action==='open-team-invite'){
  activeTab='team';render();
  queueMicrotask(()=>app.querySelector('#team-invite-panel')?.scrollIntoView({behavior:'smooth',block:'start'}));
  return;
 }
 if(action==='delete-group'&&!busy){
  if(!confirm('¿Borrar este grupo? Los socios no se eliminan.'))return;
  busy=true;render();
  try{await auth.deleteBusinessGroup(actionable.dataset.id);selectedGroupId=null;await loadSelectedOrg();notice='Grupo borrado.';}
  catch(e){error=e.message||'No se pudo borrar el grupo';}
  finally{busy=false;render();}
  return;
 }
 if(action==='revoke-member'&&!busy){
  if(!confirm('¿Quitar a este miembro del equipo?'))return;
  busy=true;render();
  try{
   await auth.manageOrgMember({orgId:selectedOrg,userId:actionable.dataset.id,action:'revoke'});
   memberships=await soft('memberships',auth.memberships(),memberships);
   notice='Miembro retirado del equipo.';
  }catch(e){error=e.message||'No se pudo retirar al miembro';}
  finally{busy=false;render();}
  return;
 }
 if(action==='cancel-team-invite'&&!busy){
  busy=true;render();
  try{await auth.cancelInvitation(actionable.dataset.id);invitations=await soft('invitations',auth.invitations(),invitations);notice='Invitación anulada.';}
  catch(e){error=e.message||'No se pudo anular';}
  finally{busy=false;render();}
  return;
 }
 if(action==='open-notifications'||action==='open-requests-modal'||action==='open-broadcast-modal'){
  businessDialog='notifications';
  if(selectedOrg&&!busy){
   busy=true;error='';render();
   try{enrollmentRequests=await auth.enrollmentRequests(selectedOrg);}
   catch(e){error=e.message||'No se pudieron cargar las solicitudes';}
   finally{busy=false;render();}
   return;
  }
  render();return;
 }
 if(action==='agenda-day-prev'||action==='agenda-day-next'||action==='agenda-day-today'){
  const d=action==='agenda-day-today'?new Date():new Date((agendaDay||todayISO())+'T12:00:00');
  if(action==='agenda-day-prev')d.setDate(d.getDate()-1);
  if(action==='agenda-day-next')d.setDate(d.getDate()+1);
  agendaDay=d.toLocaleDateString('sv-SE');calendarMonth=agendaDay.slice(0,7);render();return;
 }
 if(action==='quick-pick-exercise'){
  const form=actionable.closest('form')||app.querySelector('form[data-connected="quick-workout"]');
  const box=form?.querySelector('[data-quick-movements]');
  if(form&&box){
   const id=actionable.dataset.id||'custom';
   const name=actionable.dataset.name||'Ejercicio';
   const art=actionable.dataset.art||'';
   const known=MOVEMENTS.find(m=>m.id===id)||{id,name,art};
   const sets=form.sets?.value||3,reps=form.reps?.value||8,kg=form.weight?.value||0,rir=form.rir?.value||2;
   box.querySelector('.pt-session-empty')?.remove();
   box.insertAdjacentHTML('beforeend',`<article class="pt-session-card" data-quick-ex data-id="${escapeHTML(id)}" data-name="${escapeHTML(name)}" data-art="${escapeHTML(art)}">
    ${exerciseThumbHTML(known,{size:'exercise-thumb-lg'})}
    <div class="pt-session-card-body">
     <strong>${escapeHTML(name)}</strong>
     <div class="pt-quick-nums pt-session-nums">
      <label>Series<input data-q-sets type="number" min="1" max="50" value="${escapeHTML(sets)}"></label>
      <label>Reps<input data-q-reps type="number" min="0" max="1000" value="${escapeHTML(reps)}"></label>
      <label>Kg<input data-q-weight type="number" min="0" max="1000" step="0.5" value="${escapeHTML(kg)}"></label>
      <label>RIR<input data-q-rir type="number" min="0" max="10" value="${escapeHTML(rir)}"></label>
     </div>
    </div>
    <button type="button" class="editor-icon-button" data-action="quick-remove-chip" aria-label="Quitar">×</button>
   </article>`);
  }
  return;
 }
 if(action==='quick-remove-chip'){
  const card=actionable.closest('[data-quick-ex], .pt-quick-chip');
  const box=card?.parentElement;
  card?.remove();
  if(box&&!box.querySelector('[data-quick-ex]'))
   box.insertAdjacentHTML('afterbegin','<p class="pt-session-empty">Toca un ejercicio de la biblioteca para armar la sesión.</p>');
  return;
 }
 if(action==='open-quick-workout'){
  quickWorkoutClient=actionable.dataset.id||selectedClientId||'';
  selectedClientId=actionable.dataset.id||selectedClientId||quickWorkoutClient||null;
  planningClientId=selectedClientId;
  if(actionable.dataset.day){agendaDay=actionable.dataset.day;planningSelectedDay=actionable.dataset.day;dialogDay=actionable.dataset.day;}
  else if(!planningSelectedDay){planningSelectedDay=agendaDay||todayISO();dialogDay=planningSelectedDay;}
  selectedTemplateId=null;editingSessionId=null;seedPrescription=null;assignTemplateId='';
  copyBrowseClientId='';clientEditorOpen=false;clientSection='training';
  businessDialog='new-client-workout';activeTab='clients';
  resetEditorPanels();
  setWorkspaceRoute();render();return;
 }
 if(action==='quick-plan-day'||action==='plan-client'){
  quickWorkoutClient=actionable.dataset.id||selectedClientId||'';
  selectedClientId=actionable.dataset.id||selectedClientId||quickWorkoutClient||null;
  planningClientId=selectedClientId;
  if(actionable.dataset.day){agendaDay=actionable.dataset.day;planningSelectedDay=actionable.dataset.day;}
  else if(!planningSelectedDay)planningSelectedDay=agendaDay||todayISO();
  selectedTemplateId=null;editingSessionId=null;seedPrescription=null;copyBrowseClientId='';
  clientEditorOpen=true;clientSection='training';businessDialog='';
  activeTab='clients';
  resetEditorPanels();
  setWorkspaceRoute();render();return;
 }
 if(action==='coach-ack'&&!busy){
  busy=true;error=notice='';render();
  try{
   await auth.coachAckOccurrence({occurrenceId:actionable.dataset.id,ack:actionable.dataset.ack});
   await loadGymAssignments();notice=actionable.dataset.ack==='accepted'?'Clase aceptada.':'Clase rechazada.';
   if(actionable.dataset.ack==='declined')businessDialog='';
  }catch(e){error=e.message||'No se pudo responder';}
  finally{busy=false;render();}return;
 }
 if(action==='detail-gym-assignment'||action==='reschedule-occurrence'&&gymAssignments.some(g=>g.id===actionable.dataset.id)){
  selectedClassId=actionable.dataset.id;businessDialog='gym-assignment';render();return;
 }
 if(action==='reschedule-occurrence'){
  selectedClassId=actionable.dataset.id;businessDialog='occurrence';classEditorId=actionable.dataset.id;render();return;
 }
 if(action==='coach-cancel-occurrence'&&!busy){
  if(!confirm('¿Cancelar esta clase del gimnasio y devolver los créditos de las reservas?'))return;
  busy=true;error=notice='';render();
  try{
   const credited=await auth.coachCancelOccurrence(actionable.dataset.id);
   businessDialog='';selectedClassId=null;await loadGymAssignments();
   notice='Clase cancelada. Reservas reembolsadas: '+credited;
  }catch(e){error=e.message||'No se pudo cancelar';}
  finally{busy=false;render();}return;
 }
 if(action==='go-invite-client-legacy'){
  selectedClientId=null;activeTab='clients';setWorkspaceRoute();render();
  queueMicrotask(()=>app.querySelector('#invite-client-form')?.scrollIntoView({behavior:'smooth',block:'start'}));
  return;
 }
 if(action==='detail-client-passes'){
  selectedClientId=actionable.dataset.id;planningClientId=selectedClientId;clientSection='passes';
  clientEditorOpen=false;sharedHistory=[];activeTab='clients';businessDialog='';setWorkspaceRoute();render();
  return;
 }
 if((action==='mark-booking-attended'||action==='mark-booking-noshow')&&!busy){
  const status=action==='mark-booking-attended'?'attended':'no_show';
  const label=status==='attended'?'asistió':'no se presentó';
  if(!confirm(status==='attended'
   ?'¿Confirmar asistencia? El crédito ya se descontó al reservar; no se vuelve a cobrar.'
   :'¿Marcar como no presentado? El crédito de la reserva se mantiene consumido según la política actual.'))return;
  busy=true;error=notice='';render();
  try{
   await auth.markClassAttendance({bookingId:actionable.dataset.id,status});
   await loadSelectedOrg();
   notice='Reserva actualizada: el cliente '+label+'.';
  }catch(e){error=e.message||'No se pudo registrar la asistencia';}
  finally{busy=false;render();}
  return;
 }
 if(action==='close-business-dialog'||action==='close-invite-share'){
  if(['publish-class-plan','assign-class-training'].includes(businessDialog)){
   seedPrescription=null;draftSessionMeta=null;assignScope='one';resetEditorPanels();
  }
  businessDialog='';render();return;
 }
 if(trainer&&action==='back-classes'){
  businessDialog='';selectedClassId=null;render();return;
 }
 if(action==='trainer-session'&&trainer){selectedClientId=actionable.dataset.id;businessDialog='trainer-session';render();return;}
 if(action==='new-date-appointment'&&trainer){
  dialogDay=actionable.dataset.day||agendaDay||todayISO();
  agendaDay=dialogDay;calendarMonth=dialogDay.slice(0,7);
  if(actionable.dataset.client){selectedClientId=actionable.dataset.client;quickWorkoutClient=selectedClientId;}
  businessDialog='new-appointment';render();return;
 }
 if(action==='calendar-today'){calendarMonth='';render();return;}
 if(action==='bulk-mode'){bulkMode=actionable.dataset.mode==='template'?'template':'custom';render();return;}
 if(action==='add-planning'&&trainer){if(actionable.dataset.id){selectedClientId=actionable.dataset.id;planningClientId=selectedClientId;}bulkMode='custom';businessDialog='bulk';render();return;}
 if(action==='delete-session'&&!busy){if(!confirm('¿Eliminar este entrenamiento programado? No se borrarán actividades ya realizadas por el deportista.'))return;busy=true;render();try{await auth.cancelProfessionalSession(actionable.dataset.id);await loadSelectedOrg();notice='Entrenamiento retirado de la planificación.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='end-client'&&trainer&&!busy){const client=clients.find(c=>c.id===actionable.dataset.id);if(!client)return;if(!confirm('Confirma que el contrato profesional ya ha vencido. La cuenta personal del deportista y sus suscripciones independientes se conservarán.'))return;busy=true;render();try{await auth.updateClientProfile({orgId:selectedOrg,id:client.id,name:client.name,email:client.email,phone:client.phone||'',notes:client.notes||'',avatar:client.avatar_url||'',status:'cancelled'});await loadSelectedOrg();notice='Relación profesional finalizada; la cuenta personal no se ha cancelado.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='detail-client'){selectedClientId=actionable.dataset.id;selectedGroupId=null;planningClientId=selectedClientId;clientSection='training';clientEditorOpen=false;trainerActivityMonth='';trainerActivityDay='';sharedHistory=[];activeTab='clients';businessDialog='';setWorkspaceRoute();render();try{
    const client=clients.find(c=>c.id===selectedClientId);
    sharedHistory=client?.account_deleted_at
     ?await auth.archivedAthleteResults({orgId:selectedOrg,clientId:selectedClientId})
     :await auth.sharedClientHistory({orgId:selectedOrg,clientId:selectedClientId});
   }catch(e){error='El historial histórico o privado no está disponible para este profesional.';}render();return;}
 if(action==='back-clients'){sharedHistory=[];clientEditorOpen=false;selectedClientId=null;selectedGroupId=null;planningClientId=null;editingSessionId=null;selectedTemplateId=null;activeTab='clients';setWorkspaceRoute();render();return;}
 if(action==='client-section'){
  clientSection=actionable.dataset.section||'training';clientEditorOpen=false;render();
  if(clientSection==='chat'&&selectedClientId&&selectedOrg){
   try{
    chatMessages=await auth.listThread({orgId:selectedOrg,clientId:selectedClientId})||[];
    await auth.markThreadRead({orgId:selectedOrg,clientId:selectedClientId}).catch(()=>{});
    error='';
   }catch(e){
    chatMessages=[];
    error=e.message||'No se pudo cargar la conversación';
   }
   render();
  }
  return;
 }
 if(action==='trainer-day'&&trainer){trainerActivityDay=actionable.dataset.day;trainerActivityMonth=trainerActivityDay.slice(0,7);clientEditorOpen=false;render();return;}
 if(action==='trainer-month'&&trainer){const month=trainerActivityMonth||new Date().toLocaleDateString('sv-SE').slice(0,7);const d=new Date(month+'-01T12:00:00');d.setMonth(d.getMonth()+(Number(actionable.dataset.step)||0));trainerActivityMonth=d.toLocaleDateString('sv-SE').slice(0,7);trainerActivityDay=trainerActivityMonth+'-01';clientEditorOpen=false;render();return;}
 if(action==='close-client-editor'){clientEditorOpen=false;selectedTemplateId=null;editingSessionId=null;seedPrescription=null;copyBrowseClientId='';quickWorkoutClient='';draftSessionMeta=null;resetEditorPanels();render();return;}
 if(action==='new-library-template'){libraryTemplateId=null;activeTab='workouts';resetEditorPanels();render();return;}
 if(action==='edit-library-template'){libraryTemplateId=actionable.dataset.id;activeTab='workouts';render();return;}
 if(action==='delete-library-template'&&!busy){
  if(!confirm('¿Eliminar esta plantilla de Mis entrenos? No borra sesiones ya publicadas a clientes.'))return;
  busy=true;error=notice='';render();
  try{
   await auth.deleteWorkoutTemplate({id:actionable.dataset.id,orgId:selectedOrg});
   if(libraryTemplateId===actionable.dataset.id)libraryTemplateId=null;
   templates=await auth.workoutTemplates(selectedOrg);notice='Plantilla eliminada.';
  }catch(e){error=e.message||'No se pudo eliminar';}
  finally{busy=false;render();}return;
 }
 if(action==='insert-template'||action==='copy-session'){
  const form=app.querySelector('form[data-connected="publish-session"]');
  const current=form?readPrescription(form):(seedPrescription||emptyPrescription());
  draftSessionMeta={
   title:form?.querySelector('[name="title"]')?.value||draftSessionMeta?.title||'',
   date:form?.querySelector('[name="date"]')?.value||draftSessionMeta?.date||planningSelectedDay||'',
   instructions:form?.querySelector('[name="instructions"]')?.value||draftSessionMeta?.instructions||'',
  };
  let extra=emptyPrescription();
  if(action==='insert-template'){
   const tpl=templates.find(t=>t.id===actionable.dataset.id);if(!tpl){error='Plantilla no encontrada';render();return;}
   extra=tpl.prescription;notice='Plantilla añadida. Adáptala antes de publicar.';
  }else{
   const ses=professionalSessions.find(s=>s.id===actionable.dataset.id);if(!ses){error='Sesión no encontrada';render();return;}
   extra=ses.prescription;notice='Entreno copiado. Adáptalo para este cliente.';
   if(!String(draftSessionMeta.title||'').trim())draftSessionMeta.title=ses.title||'';
  }
  seedPrescription=mergePrescriptionBlocks(current,extra);
  selectedTemplateId=null;
  render();return;
 }
 if(action==='detail-group'){selectedGroupId=actionable.dataset.id;selectedClientId=null;selectedClassId=null;activeTab='clients';businessDialog=trainer?'group':'';render();return;}
 if(action==='back-groups'){selectedGroupId=null;activeTab='clients';businessDialog='';render();return;}
 if(action==='detail-occurrence'){
  selectedGroupId=null;classEditorId=null;selectedClassId=actionable.dataset.id;
  const occ=occurrences.find(x=>x.id===selectedClassId);
  // Clases grupales: modal Editar (esta / serie), sin saltar a otra pantalla 360.
  if(occ?.kind==='class'){
   agendaDay=new Date(occ.starts_at).toLocaleDateString('sv-SE');
   activeTab='overview';
   expandedOccurrenceId=occ.id;
   assignTemplateId='';
   assignScope='one';
   const det=classDetails.find(d=>d.occurrence_id===occ.id)||{};
   seedPrescription=det.prescription||null;
   draftSessionMeta={title:det.training_title||'',instructions:det.training_instructions||''};
   businessDialog='edit-class';
   render();return;
  }
  if(trainer){businessDialog='occurrence';}
  else{
   expandedOccurrenceId=selectedClassId;
   if(occ)agendaDay=new Date(occ.starts_at).toLocaleDateString('sv-SE');
   activeTab='overview';
  }
  render();return;
 }
 if(action==='back-classes'){classEditorId=null;selectedClassId=null;expandedOccurrenceId='';activeTab='overview';render();return;}
 if(action==='open-class-calendar'){selectedClassId=null;classMode='calendar';activeTab='overview';setWorkspaceRoute();render();return;}
 if(action==='calendar-mode'){classMode=actionable.dataset.mode==='list'?'list':'calendar';render();return;}
 if(action==='calendar-prev'||action==='calendar-next'){
  const first=(calendarMonth?new Date(calendarMonth+'-01T12:00:00'):new Date());
  first.setDate(1);first.setMonth(first.getMonth()+(action==='calendar-next'?1:-1));
  calendarMonth=first.toLocaleDateString('sv-SE').slice(0,7);render();return;
 }
 if(action==='publish-class-plan'){
  classEditorId=actionable.dataset.id;
  selectedClassId=actionable.dataset.id;
  expandedOccurrenceId=selectedClassId;
  assignClassDay='';
  assignTemplateId='';
  assignOnlyWithout=false;
  assignPreselectedIds=[actionable.dataset.id];
  assignScope='one';
  seedPrescription=null;
  draftSessionMeta=null;
  resetEditorPanels();
  businessDialog='publish-class-plan';
  if(!trainer)activeTab='overview';
  render();
  return;
 }
 if(action==='clear-class-plan'&&!busy){
  const occurrenceId=actionable.dataset.id;
  if(!/^[0-9a-f-]{36}$/i.test(occurrenceId||'')){error='Clase inválida';render();return;}
  if(!confirm('¿Quitar el entreno de esta clase? Los inscritos dejarán de verlo en la app. No se borra ninguna plantilla de Mis entrenos.'))return;
  busy=true;error=notice='';render();
  try{
   const n=await auth.clearClassTraining({occurrenceId});
   businessDialog='';
   await loadSelectedOrg();
   notice=Number(n)>0
    ?`Entreno quitado de la clase (${n} publicación${Number(n)===1?'':'es'} cancelada${Number(n)===1?'':'s'} a inscritos).`
    :'Entreno quitado de la clase.';
  }catch(e){error=e.message||'No se pudo quitar el entreno';}
  finally{busy=false;render();}
  return;
 }
 if(action==='assign-day-class-training'){
  assignClassDay=actionable.dataset.day||agendaDay||todayISO();
  agendaDay=assignClassDay;
  assignTemplateId='';
  assignOnlyWithout=false;
  assignPreselectedIds=[];
  assignScope='one';
  seedPrescription=null;
  draftSessionMeta=null;
  resetEditorPanels();
  businessDialog='assign-class-training';
  activeTab='overview';
  render();
  return;
 }
 if(action==='assign-template-to-classes'){
  const tpl=templates.find(t=>t.id===actionable.dataset.id);
  if(!tpl){error='Plantilla no encontrada';render();return;}
  assignClassDay=agendaDay||todayISO();
  assignTemplateId=tpl.id;
  assignOnlyWithout=false;
  assignPreselectedIds=[];
  seedPrescription=tpl.prescription||null;
  businessDialog='assign-class-training';
  activeTab='overview';
  render();
  return;
 }
 if(action==='assign-select-all'||action==='assign-select-none'){
  const form=actionable.closest('form[data-assign-class-form]');
  form?.querySelectorAll('input[name="occurrences"]').forEach(inp=>{
   if(!inp.disabled)inp.checked=action==='assign-select-all';
  });
  return;
 }
 if(action==='find-class-for-client'){selectedClientId=actionable.dataset.id;selectedClassId=null;activeTab='overview';notice='Abre una clase en Inicio y pulsa Añadir participante.';render();return;}
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
  const accept=action==='approve-enrollment';
  const requestId=actionable.dataset.id;
  const pendingReq=enrollmentRequests.find(r=>r.id===requestId);
  const athleteId=pendingReq?.athlete_id||null;
  busy=true;error=notice='';render();
  try{
   const decision=await auth.decideEnrollment(requestId,accept);
   // Clientes primero: si falla el resto del panel, la ficha nueva igual se ve.
   clients=await auth.clients(selectedOrg,{basic:false});
   enrollmentRequests=await soft('enrollments',auth.enrollmentRequests(selectedOrg),[]);
   await loadSelectedOrg().catch(e=>{if(e.status===401)throw e;});
   businessDialog='';
   if(accept){
    let pick=decision.client_id?clients.find(c=>c.id===decision.client_id):null;
    if(!pick&&athleteId)pick=clients.find(c=>c.user_id===athleteId);
    if(!pick){
     pick=clients.filter(c=>c.user_id&&c.status==='active'&&!c.account_deleted_at)
      .sort((a,b)=>String(b.updated_at||b.created_at||'').localeCompare(String(a.updated_at||a.created_at||'')))[0]||null;
    }
    selectedClientId=pick?.id||decision.client_id||null;
    planningClientId=selectedClientId;
    clientSection='training';
    clientEditorOpen=false;
    activeTab='clients';
    setWorkspaceRoute();
    notice=pick
     ?`Solicitud aceptada. ${pick.name} ya está en Clientes y vinculado.`
     :'Solicitud aceptada. Si no ves al cliente, pulsa Actualizar o recarga.';
   }else{
    notice='Solicitud rechazada. Se ha registrado la decisión.';
   }
  }catch(e){
   const msg=e.message||'No se pudo procesar la solicitud';
   if(/TRAINER_CLIENT_LIMIT|TRIAL_EXPIRED/i.test(msg))
    error='No se pudo aceptar: revisa el cupo de clientes o que la prueba/plan siga activo. '+msg;
   else error=msg;
  }
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
 if((action==='copy-invite-link'||action==='copy-invite-deep')&&actionable.dataset.url){
  try{await navigator.clipboard.writeText(actionable.dataset.url);notice='Enlace copiado.';render();}
  catch{error='No se pudo copiar el enlace.';render();}return;}
 if(action==='cancel-invitation'&&!busy){
  busy=true;error=notice='';render();
  try{await auth.cancelInvitation(actionable.dataset.id);lastInviteShare=null;await reload();notice='Invitación revocada.';}
  catch(e){error=e.message||'No se pudo revocar';}finally{busy=false;render();}return;}
 if(action==='invite-client'&&!busy){const c=clients.find(c=>c.id===actionable.dataset.id);
  if(!c||c.user_id)return;
  const orgRow=organizations.find(o=>o.id===selectedOrg);
  const waWin=beginInvitationWhatsappPopup(orgRow);
  busy=true;error=notice='';render();
  try{
   const existing=pendingAthleteInvite({invitations,orgId:selectedOrg,email:c.email});
   let id=existing?.id||'';
   let emailResult={sent:false,reason:''};
   if(!id){
    id=asUuid(await auth.issueInvitation({orgId:selectedOrg,email:c.email,role:'athlete'}));
    if(!id)throw Error('No se pudo crear la invitación');
    emailResult=await auth.sendInvitationEmail(id);
   }
   invitations=await soft('invitations',auth.invitations(),invitations);
   lastInviteShare={invitationId:id,email:c.email,sent:!!emailResult.sent,reason:emailResult.reason||''};
   businessDialog='';activeTab='clients';selectedClientId=c.id;clientSection='data';
   const wa=finishInvitationWhatsappPopup(waWin,{org:orgRow,clientName:c.name,clientPhone:c.phone||'',invitationId:id});
   notice=wa?'WhatsApp abierto':(emailResult.sent?'Invitación enviada':'QR en la ficha');
  }catch(e){try{waWin?.close();}catch{/* ignore */}error=e.message;}finally{busy=false;render();}return;}
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
  if(!confirm('¿Cancelar esta clase? Se reembolsará a los apuntados y quedará bloqueada en el calendario.'))return;
  busy=true;render();
  try{
   const credited=await auth.cancelManagedOccurrence(actionable.dataset.id);
   businessDialog='';await reload();
   notice='Clase cancelada. Reservas reembolsadas: '+credited;
  }catch(e){error=e.message;}
  finally{busy=false;render();}
  return;
 }
 if(action==='delete-occurrence'&&!busy){
  if(!confirm('¿Borrar esta clase del calendario? Se reembolsará a los apuntados y desaparecerá de la agenda.'))return;
  busy=true;render();
  try{
   const credited=await auth.deleteManagedOccurrence(actionable.dataset.id);
   selectedClassId=null;expandedOccurrenceId='';businessDialog='';await reload();
   notice='Clase borrada. Reservas reembolsadas: '+credited;
  }catch(e){error=e.message;}
  finally{busy=false;render();}
  return;
 }
 if(action==='remove-booking'&&!busy){
  if(!confirm('¿Quitar a este deportista y devolver el crédito de la reserva?'))return;
  busy=true;render();try{await auth.removeManagedClient(actionable.dataset.id);await loadSelectedOrg();notice='Participante retirado y crédito devuelto.';}catch(e){error=e.message;}finally{busy=false;render();}return;
 }
 if(action==='new-workout'){selectedTemplateId=null;editingSessionId=null;seedPrescription=null;render();return;}
 if(action==='use-template'){
  selectedTemplateId=actionable.dataset.id;editingSessionId=null;seedPrescription=null;
  clientEditorOpen=true;clientSection='training';activeTab='clients';
  setWorkspaceRoute();render();return;
 }
 if(action==='edit-session'){
  editingSessionId=actionable.dataset.id;selectedTemplateId=null;seedPrescription=null;
  const session=professionalSessions.find(s=>s.id===editingSessionId);
  if(session){selectedClientId=session.client_id;planningClientId=selectedClientId;quickWorkoutClient=session.client_id;}
  clientEditorOpen=true;clientSection='training';
  activeTab='clients';setWorkspaceRoute();render();return;
 }
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
 const clientFilter=event.target.closest('[data-client-filter]');
 if(clientFilter){
  clientQuery=clientFilter.value;
  const at=clientFilter.selectionStart;
  render();
  const el=app.querySelector('[data-client-filter]');el?.focus();
  if(typeof at==='number')el?.setSelectionRange(at,at);
  return;
 }
 const reception=event.target.closest('[data-reception-filter]');
 if(reception){
  const q=reception.value.trim().toLowerCase();
  app.querySelectorAll('[data-reception-name]').forEach(row=>{
   row.hidden=q!==''&&!row.dataset.receptionName.includes(q);
  });
  return;
 }
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
 if(event.target.matches('[data-quick-search]')){
  const q=event.target.value.trim().toLowerCase();
  const grid=event.target.closest('form')?.querySelector('[data-quick-picker]');
  grid?.querySelectorAll('.pt-ex-tile').forEach(tile=>{
   tile.hidden=!!(q&&!(tile.dataset.search||'').includes(q));
  });
  return;
 }
 handleEditorSearch(event);
 if(event.target.name==='name'&&event.target.closest('form[data-connected="create"]')){
  const preview=event.target.closest('form').querySelector('[data-generated-slug]');
  if(preview){try{preview.textContent=slugFromName(event.target.value)+'-xxxxxxxx';}catch{preview.textContent='Se generará automáticamente';}}
 }
});
app.addEventListener('change',async event=>{
 if(event.target.closest('form[data-assign-class-form]')){
  const form=event.target.closest('form[data-assign-class-form]');
  const stayDialog=businessDialog==='edit-class'||businessDialog==='new-class'||businessDialog==='new-client-workout'?businessDialog
   :businessDialog==='publish-class-plan'?'publish-class-plan':'assign-class-training';
  if(event.target.name==='templateId'){
   assignTemplateId=event.target.value||'';
   const tpl=templates.find(t=>t.id===assignTemplateId);
   // Copia de la plantilla para esta clase (no se edita la plantilla original).
   seedPrescription=tpl?.prescription?structuredClone(tpl.prescription):null;
   if(tpl&&(businessDialog==='edit-class'||businessDialog==='new-class'||businessDialog==='new-client-workout')){
    draftSessionMeta={title:tpl.name||'',instructions:draftSessionMeta?.instructions||''};
   }
   const checked=[...form.querySelectorAll('input[name="occurrences"]:checked')].map(i=>i.value);
   const locked=[...form.querySelectorAll('input[name="occurrences"][type="hidden"]')].map(i=>i.value);
   assignPreselectedIds=checked.length?checked:locked;
   assignOnlyWithout=!!form.querySelector('[name="onlyWithout"]')?.checked;
   assignClassDay=form.querySelector('[name="day"]')?.value||assignClassDay;
   businessDialog=stayDialog;
   render();
   return;
  }
  if(event.target.name==='assignScope'){
   assignScope=event.target.value||'one';
   return;
  }
  if(event.target.name==='onlyWithout'||event.target.matches('[data-action="assign-only-without"]')){
   assignOnlyWithout=!!event.target.checked;
   assignPreselectedIds=[];
   assignClassDay=form.querySelector('[name="day"]')?.value||assignClassDay;
   businessDialog='assign-class-training';
   render();
   return;
  }
 }
 if(event.target.closest('form[data-connected="quick-workout"]')&&
    (event.target.matches('[data-quick-mode], [name="weekdays"], [name="date"], [name="end"], [name="weeks"]')||
     event.target.name==='mode')){
  syncQuickWorkoutForm(event.target.closest('form[data-connected="quick-workout"]'));
  return;
 }
 if(event.target.matches('[data-billing-select]')){syncBillingFields();return;}
 if(event.target.matches('[data-appt-kind]')){
  const form=event.target.closest('form');
  const isAppt=event.target.value==='appointment';
  form?.querySelector('[data-appt-client-fields]')?.toggleAttribute('hidden',!isAppt);
  form?.querySelector('[data-appt-group-fields]')?.toggleAttribute('hidden',isAppt);
  if(isAppt){const cap=form?.querySelector('[name="capacity"]');if(cap)cap.value='1';}
  return;
 }
 if(event.target.matches('[data-appt-pass]')&&event.target.selectedOptions[0]?.dataset.client){
  const form=event.target.closest('form');
  const client=form?.querySelector('[name="client"]');
  if(client)client.value=event.target.selectedOptions[0].dataset.client;
  return;
 }
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
 if(event.target.matches('select[data-action="copy-browse-client"]')){
  copyBrowseClientId=event.target.value||'';render();return;
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
 // Validar WhatsApp antes del re-render (si no, el input vuelve al número antiguo y parece que «no deja» cambiarlo).
 if(action==='whatsapp-connect'){
  whatsappDraft=String(data.get('whatsapp')||'');
  if(!parseWhatsappE164(whatsappDraft)){
   error='Número de WhatsApp inválido. Usa prefijo país, p. ej. +34600111222.';
   notice='';settingsSection='services';activeTab='settings';render();return;
  }
 }
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
 const stashWorkoutDraft=()=>{
  draftSessionMeta={
   ...(draftSessionMeta||{}),
   title:String(data.get('title')||data.get('name')||draftSessionMeta?.title||''),
   instructions:String(data.get('instructions')||draftSessionMeta?.instructions||''),
   date:String(data.get('date')||draftSessionMeta?.date||''),
  };
 };
 try{if(['publish-session','publish-class-plan','publish-class-plan-bulk','bulk-custom','save-workout-template'].includes(action)
  ||((action==='edit-occurrence'||action==='service-occurrence')&&data.get('saveTraining')==='1'&&f.querySelector('.workout-editor'))){
  const visual=validatePrescription(readPrescription(f));
  // Conservar borrador visual antes de busy/render (si falla el RPC no debe «resetear» el editor).
  seedPrescription=visual;
  stashWorkoutDraft();
  prescription=withSessionMeta(canonicalPrescription(visual),readSessionMeta(f));
 }}catch(e){
  try{seedPrescription=readPrescription(f);}catch{/* ignore */}
  stashWorkoutDraft();
  const preview=f.querySelector('[data-custom-preview]');if(preview){preview.textContent=e.message;preview.classList.add('is-invalid');return;}
  error=e.message;notice='';render();return;
 }
 // Conservar borrador de invitación antes del re-render (busy vacía el DOM).
 if(action==='client'){
  inviteDraft={
   name:String(data.get('name')||'').trim(),
   email:String(data.get('email')||'').trim().toLowerCase(),
   phone:String(data.get('phone')||'').trim(),
   passMode:String(data.get('passMode')||'none'),
   trialCredits:String(data.get('trialCredits')||'3'),
   trialDays:String(data.get('trialDays')||'30'),
   trialKind:String(data.get('trialKind')||''),
   offerId:String(data.get('offer')||''),
   paymentMethod:String(data.get('paymentMethod')||'cash'),
   paidAmount:String(data.get('paidAmount')||''),
   paymentNote:String(data.get('paymentNote')||''),
  };
  inviteEmailError='';
  showInviteModal=true;
 }
 // Capturar franjas antes de re-render (el form desaparece del DOM).
 const classScheduleMode=action==='service-occurrence'&&f.hasAttribute('data-class-week-create')
  ?String(data.get('scheduleMode')||'unique')
  :'';
 const weekClassSlots=classScheduleMode==='weekly'
  ?data.getAll('slot').map(String).filter(Boolean)
  :null;
 const passOfferSlots=(action==='create-pass-offer'||action==='update-pass-offer')
  ?[...f.querySelectorAll('input[name="slotWeekdays"]:checked')].map(x=>Number(x.value)).filter(n=>n>=1&&n<=7)
  :null;
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
   const email=String(data.get('email')||'').trim().toLowerCase();
   const role=data.get('role');
   const orgRow=organizations.find(o=>o.id===selectedOrg);
   const waWin=role==='athlete'?beginInvitationWhatsappPopup(orgRow):null;
   const id=asUuid(await auth.issueInvitation({orgId:selectedOrg,email,role}));
   if(!id){try{waWin?.close();}catch{/* ignore */}throw Error('No se pudo crear la invitación');}
   let delivery={sent:false,reason:'Envío pendiente'};
   try{delivery=await auth.sendInvitationEmail(id);}catch(e){delivery={sent:false,reason:e.message||'Envío no confirmado'};}
   invitations=await soft('invitations',auth.invitations(),invitations);
   lastInviteShare=role==='athlete'?{invitationId:id,email,sent:!!delivery.sent,reason:delivery.reason||''}:null;
   businessDialog='';
   activeTab=role==='athlete'?'clients':'team';
   if(role==='athlete'){
    const client=clients.find(c=>String(c.email||'').toLowerCase()===email);
    selectedClientId=client?.id||selectedClientId;
    clientSection='data';
    finishInvitationWhatsappPopup(waWin,{org:orgRow,clientName:client?.name||'',clientPhone:client?.phone||'',invitationId:id});
   }
   await reload();
   notice=delivery.sent?'Invitación enviada':(role==='athlete'?'QR en la ficha':'Invitación creada');
  }
  if(action==='save-workout-template'){
   const name=String(data.get('name')||'').trim();
   const id=data.get('template');
   if(id)await auth.updateWorkoutTemplate({id,orgId:selectedOrg,name,description:data.get('description'),prescription});
   else{
    const created=await auth.createWorkoutTemplate({orgId:selectedOrg,name,description:data.get('description'),prescription,userId:user.id});
    libraryTemplateId=created?.[0]?.id||created?.id||libraryTemplateId;
   }
   templates=await auth.workoutTemplates(selectedOrg);
   notice='Plantilla guardada en Mis entrenos.';
   activeTab='workouts';
  }
  if(action==='publish-session'){
   if(intent==='template'){
    const name=data.get('templateName')||data.get('title');
    if(selectedTemplateId)await auth.updateWorkoutTemplate({id:selectedTemplateId,orgId:selectedOrg,name,description:data.get('templateDescription'),prescription});
    else await auth.createWorkoutTemplate({orgId:selectedOrg,name,description:data.get('templateDescription'),prescription,userId:user.id});
    selectedTemplateId=null;seedPrescription=null;notice='Plantilla guardada en Mis entrenos.';
    templates=await auth.workoutTemplates(selectedOrg);
   }else if(editingSessionId){
    await auth.updateProfessionalSession({id:editingSessionId,date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    await auth.setProfessionalSessionTime(editingSessionId,String(data.get('time')||''));
    editingSessionId=null;seedPrescription=null;notice='Cambios del entrenamiento individual guardados.';
   }else{
    const sessionId=await auth.publishProfessionalSession({orgId:selectedOrg,clientId:data.get('client'),date:data.get('date'),title:data.get('title'),instructions:data.get('instructions'),prescription});
    await auth.setProfessionalSessionTime(sessionId,String(data.get('time')||''));
    selectedTemplateId=null;seedPrescription=null;notice='Entrenamiento profesional publicado.';
   }
   await reload();
   if(intent==='publish'){
    clientEditorOpen=false;copyBrowseClientId='';draftSessionMeta=null;
    assignTemplateId='';seedPrescription=null;
    if(businessDialog==='new-client-workout')businessDialog='';
   }
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
   classEditorId=null;businessDialog='';
   await loadSelectedOrg();
   notice=count>0
    ?`Entreno de la clase guardado y publicado a ${count} inscrito${count===1?'':'s'} con app.`
    :'Entreno de la clase guardado. Se enviará a cada socio cuando se apunte (con cuenta vinculada).';
  }
  if(action==='publish-class-plan-bulk'){
   const selected=data.getAll('occurrences').filter(Boolean);
   if(!selected.length)throw Error('Marca al menos una clase');
   const scope=String(data.get('assignScope')||'one');
   const day=String(data.get('day')||assignClassDay||'');
   const ids=resolveAssignScopeIds({
    scope,baseId:selected[0],day,occurrences,selectedIds:selected,
   });
   if(!ids.length)throw Error('No hay clases en el alcance elegido');
   const raw=await auth.publishClassTrainingBulk({
    occurrenceIds:ids,
    title:data.get('title'),
    instructions:data.get('instructions')||'',
    prescription,
   });
   const result=Array.isArray(raw)?raw[0]:raw;
   const occN=Number(result?.occurrences||ids.length);
   const athN=Number(result?.athletes||0);
   businessDialog='';assignClassDay='';assignTemplateId='';assignPreselectedIds=[];assignScope='one';seedPrescription=null;draftSessionMeta=null;
   await loadSelectedOrg();
   const scopeLabel=scope==='series'?' (serie)':scope==='day'?' (día)':'';
   notice=athN>0
    ?`Entreno asignado a ${occN} clase${occN===1?'':'s'}${scopeLabel} · ${athN} inscrito${athN===1?'':'s'} con app.`
    :`Entreno asignado a ${occN} clase${occN===1?'':'s'}${scopeLabel}. Se enviará a quien se apunte con cuenta vinculada.`;
  }
  if(action==='service-occurrence'){
   const kind=data.get('kind')||'appointment';
   const capacity=kind==='appointment'?1:Math.max(1,Number(data.get('capacity')||8));
   const coachRaw=String(data.get('coach')||'').trim();
   const coachId=/^[0-9a-f-]{36}$/i.test(coachRaw)?coachRaw:null;
   const roomId=String(data.get('room_id')||'').trim()||null;
   const activityTypeId=String(data.get('activity_type_id')||'').trim()||null;
   if(kind==='appointment'&&!coachId)throw Error('Elige un entrenador para la cita.');
   let ids=[];
   const pad=n=>String(n).padStart(2,'0');
   const fmtLocal=d=>`${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
   if((kind==='class'||kind==='open_access')&&weekClassSlots){
    const slots=weekClassSlots;
    if(!slots.length)throw Error('Marca al menos un día y una franja en la semana.');
    const durationMin=Math.min(12*60,Math.max(15,Number(data.get('duration')||60)));
    const untilMode=data.get('untilMode')||'indefinite';
    const untilRaw=String(data.get('untilDate')||'').trim();
    const untilDate=untilMode==='date'&&/^\d{4}-\d{2}-\d{2}$/.test(untilRaw)
     ?new Date(untilRaw+'T23:59:59')
     :new Date(Date.now()+62*7*24*60*60*1000);
    if(!(untilDate>new Date()))throw Error('La fecha de fin debe ser posterior a hoy.');
    const seriesRaw=String(data.get('seriesStart')||'').trim();
    const seriesFloor=/^\d{4}-\d{2}-\d{2}$/.test(seriesRaw)
     ?new Date(seriesRaw+'T00:00:00')
     :new Date();
    const nextStart=(isoDow,hour,minute=0)=>{
     const floor=seriesFloor>new Date()?seriesFloor:new Date();
     for(let i=0;i<28;i++){
      const d=new Date(floor.getFullYear(),floor.getMonth(),floor.getDate()+i,hour,minute,0,0);
      const dow=d.getDay()||7;
      if(dow===isoDow&&d>new Date()&&d>=seriesFloor)return d;
     }
     return null;
    };
    const color=data.get('color')||'#22834d';
    const location=data.get('location')||'';
    const description=data.get('description')||'';
    const title=data.get('title');
    for(const key of slots){
     const parsed=parseWeekSlotKey(key);
     if(!parsed)continue;
     const startAt=nextStart(parsed.isoDow,parsed.hour,parsed.minute);
     if(!startAt)continue;
     const endAt=new Date(startAt.getTime()+durationMin*60*1000);
     const weeks=Math.min(62,Math.max(1,Math.ceil((untilDate-startAt)/(7*24*60*60*1000))));
     const created=await auth.addClassSeries({
      orgId:selectedOrg,coachId,kind,title,
      start:fmtLocal(startAt),end:fmtLocal(endAt),capacity,
      repeat:weeks>1?'weekly':'none',count:weeks,
      color,location,description,roomId,activityTypeId,
     });
     const batch=Array.isArray(created)?created:(created?[created]:[]);
     ids=ids.concat(batch);
    }
    if(!ids.length)throw Error('No se pudo crear ninguna sesión futura con esas franjas.');
   }else if((kind==='class'||kind==='open_access')&&classScheduleMode==='unique'){
    const startAt=new Date(data.get('start'));
    if(!Number.isFinite(startAt.getTime())||startAt<=new Date())throw Error('La clase debe empezar en el futuro (elige otra hora).');
    const durationMin=Math.min(12*60,Math.max(15,Number(data.get('duration')||60)));
    const endAt=new Date(startAt.getTime()+durationMin*60*1000);
    const created=await auth.addClassSeries({
     orgId:selectedOrg,coachId,kind,title:data.get('title'),
     start:fmtLocal(startAt),end:fmtLocal(endAt),capacity,
     repeat:'none',count:1,
     color:data.get('color')||'#22834d',
     location:data.get('location')||'',
     description:data.get('description')||'',
     roomId,activityTypeId,
    });
    ids=Array.isArray(created)?created:(created?[created]:[]);
   }else{
    const startAt=new Date(data.get('start'));
    if(!Number.isFinite(startAt.getTime())||startAt<=new Date())throw Error('La clase debe empezar en el futuro (elige otra hora).');
    let repeat=data.get('repeat')||'none';
    let intervalDays=null;
    if(repeat==='every_n'){
     intervalDays=Math.min(14,Math.max(1,Number(data.get('intervalDays')||2)));
     repeat='daily';
    }
    let endValue=data.get('end');
    if(!endValue){
     const durationMin=Math.min(12*60,Math.max(15,Number(data.get('duration')||60)));
     endValue=fmtLocal(new Date(startAt.getTime()+durationMin*60*1000));
    }
    const created=await auth.addClassSeries({
     orgId:selectedOrg,coachId,kind,title:data.get('title'),
     start:data.get('start'),end:endValue,capacity,
     repeat,count:Number(data.get('repeatCount')||1),
     color:data.get('color')||'#22834d',
     intervalDays,
     location:data.get('location')||'',
     description:data.get('description')||'',
    });
    ids=Array.isArray(created)?created:(created?[created]:[]);
   }
   const occurrenceId=typeof ids[0]==='string'?ids[0]:ids[0]?.id;
   let assigned=false;let assignHint='';
   if(kind==='appointment'&&data.get('client')&&occurrenceId){
    const clientId=data.get('client');
    const client=clients.find(c=>c.id===clientId);
    let passId=asPassId(data.get('pass'));
    if(passId){
     const pass=passes.find(p=>p.id===passId);
     if(pass&&pass.client_id!==clientId)passId='';
    }
    if(!passId){
     const own=passes.find(p=>p.client_id===clientId&&p.status==='active'&&p.kind==='appointment'&&p.remaining_credits>0&&Date.parse(p.valid_until)>Date.now());
     passId=own?.id||'';
    }
    if(!passId&&client?.user_id&&client.status==='active'){
     const until=new Date(data.get('end')||Date.now());
     until.setDate(until.getDate()+14);
     passId=asPassId(await auth.grantCourtesyPass({orgId:selectedOrg,clientId,kind:'appointment',credits:1,validUntil:until.toISOString()}));
    }
    if(passId){
     await auth.enrollManagedClient({occurrenceId,clientId,passId});
     assigned=true;
    }else if(!client?.user_id){
     assignHint='El cliente aún no tiene app vinculada: la cita queda solo en tu agenda.';
    }else if(client.status!=='active'){
     assignHint='Pon al cliente en estado activo o asígnale un bono antes de reservarle la cita.';
    }else{
     assignHint='No había bono usable para asignar la reserva.';
    }
   }
   let trainingNotice='';
   if(kind==='class'&&data.get('saveTraining')==='1'&&prescription){
    const occIds=[...new Set(ids.map(x=>typeof x==='string'?x:x?.id).filter(id=>/^[0-9a-f-]{36}$/i.test(id||'')))];
    if(occIds.length){
     const trainingTitle=String(data.get('trainingTitle')||data.get('title')||'').trim();
     if(trainingTitle.length<2)throw Error('Pon un título al entrenamiento (o desmarca incluir entreno).');
     const raw=await auth.publishClassTrainingBulk({
      occurrenceIds:occIds.slice(0,40),
      title:trainingTitle,
      instructions:data.get('instructions')||'',
      prescription,
     });
     const result=Array.isArray(raw)?raw[0]:raw;
     const occN=Number(result?.occurrences||Math.min(40,occIds.length));
     trainingNotice=occN>1?` · Entreno publicado en ${occN} clases.`:' · Entreno publicado.';
     assignTemplateId='';seedPrescription=null;draftSessionMeta=null;
    }
   }
   await loadSelectedOrg();businessDialog='';
   notice=assigned
    ?'Cita creada y asignada. El cliente la verá en la app como sesión personal contigo.'
    :'Sesiones creadas: '+(ids.length||1)+(assignHint?' · '+assignHint:'')+trainingNotice;
  }
  if(action==='edit-occurrence'){
   const id=data.get('id');
   const scope=data.get('editScope')||'one';
   const payload={title:data.get('title'),start:data.get('start'),end:data.get('end'),capacity:data.get('capacity'),description:data.get('description'),location:data.get('location'),color:data.get('color'),image:data.get('image')};
   const base=occurrences.find(o=>o.id===id&&o.kind==='class');
   if(!base)throw Error('Clase no encontrada');
   const oldStart=new Date(base.starts_at);
   const newStart=new Date(payload.start);
   const newEnd=new Date(payload.end);
   const deltaStart=newStart-oldStart;
   const deltaEnd=newEnd-new Date(base.ends_at);
   const targets=scope==='series'
    ?occurrences.filter(o=>{
      if(o.org_id&&base.org_id&&o.org_id!==base.org_id)return false;
      if(o.id===id)return true;
      if(o.status!=='active'||o.kind!=='class')return false;
      if(o.title!==base.title)return false;
      const s=new Date(o.starts_at);
      if(s<oldStart)return false;
      if(s.getDay()!==oldStart.getDay())return false;
      if(s.getHours()!==oldStart.getHours()||s.getMinutes()!==oldStart.getMinutes())return false;
      return true;
     })
    :[base];
   for(const o of targets){
    const start=o.id===id?payload.start:new Date(new Date(o.starts_at).getTime()+deltaStart).toISOString();
    const end=o.id===id?payload.end:new Date(new Date(o.ends_at).getTime()+deltaEnd).toISOString();
    await auth.manageOccurrence({
     id:o.id,
     title:payload.title,
     start:o.id===id?payload.start:start,
     end:o.id===id?payload.end:end,
     capacity:payload.capacity,
     description:payload.description,
     location:payload.location,
     color:payload.color,
     image:payload.image,
    });
   }
   let trainingNotice='';
   if(data.get('saveTraining')==='1'&&prescription){
    const trainingTitle=String(data.get('trainingTitle')||payload.title||'').trim();
    if(trainingTitle.length<2)throw Error('Pon un título al entrenamiento (o desmarca guardar entreno).');
    const trainScope=String(data.get('assignScope')||'one');
    const trainIds=resolveAssignScopeIds({
     scope:trainScope,baseId:id,day:new Date(base.starts_at).toLocaleDateString('sv-SE'),
     occurrences,selectedIds:[id],
    });
    const raw=await auth.publishClassTrainingBulk({
     occurrenceIds:trainIds.length?trainIds:[id],
     title:trainingTitle,
     instructions:data.get('instructions')||'',
     prescription,
    });
    const result=Array.isArray(raw)?raw[0]:raw;
    const occN=Number(result?.occurrences||trainIds.length||1);
    trainingNotice=occN>1?` · Entreno publicado en ${occN} clases.`:' · Entreno de la clase guardado.';
    assignTemplateId='';seedPrescription=null;draftSessionMeta=null;
   }
   await loadSelectedOrg();businessDialog='';
   notice=(targets.length>1?`Serie actualizada (${targets.length} clases).`:'Clase actualizada.')+trainingNotice;
  }
  if(action==='coach-reschedule'){
   await auth.coachRescheduleOccurrence({occurrenceId:data.get('id'),start:data.get('start'),end:data.get('end')});
   await loadGymAssignments();businessDialog='';notice='Clase movida. Los atletas verán el nuevo horario en la app.';
  }
  if(action==='enroll-client'){
   const pass=passes.find(p=>p.id===data.get('pass'));if(!pass)throw Error('Selecciona un cliente con bono válido');
   await auth.enrollManagedClient({occurrenceId:data.get('occurrence'),clientId:pass.client_id,passId:pass.id});
   selectedClassId=data.get('occurrence');expandedOccurrenceId=selectedClassId;
   await loadSelectedOrg();businessDialog='';notice='Deportista inscrito y crédito descontado del bono.';
  }
  if(action==='manage-pass'){
   const op=data.get('op');await auth.changeCourtesyCredits(data.get('pass'),op,Number(data.get('amount')),data.get('until')||null);
   const managed=passes.find(p=>p.id===data.get('pass'));
   if(managed?.client_id){selectedClientId=managed.client_id;clientSection='passes';}
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
   businessDialog='';activeTab='clients';selectedClientId=null;selectedGroupId=null;
   await loadSelectedOrg();notice='Grupo creado';
  }
  if(action==='manage-member'){
   await auth.manageOrgMember({
    orgId:selectedOrg,userId:data.get('user'),action:data.get('op')||'set_role',role:data.get('role')||null,
   });
   memberships=await soft('memberships',auth.memberships(),memberships);
   notice='Rol del miembro actualizado.';
  }
  if(action==='issue-offline-pass'){
   if(data.get('confirmed')!=='yes')throw Error('Confirma la asignación fuera de Repera.');
   const paidRaw=data.get('paidAmount');
   const paidAmountCents=paidRaw===''||paidRaw==null?null:Math.round(Number(paidRaw)*100);
   if(paidAmountCents!=null&&(!Number.isFinite(paidAmountCents)||paidAmountCents<0))
    throw Error('Importe de cobro no válido');
   await auth.issueOfflinePass({
    orgId:selectedOrg,clientId:data.get('client'),offerId:data.get('offer'),
    paymentMethod:data.get('paymentMethod')||'other',
    paidAt:data.get('paidAt')||null,
    paidAmountCents,
    paymentNote:data.get('paymentNote')||'',
   });
   selectedClientId=data.get('client');clientSection='passes';businessDialog='';
   await loadSelectedOrg();notice='Bono asignado con el cobro registrado. No se ha cobrado nada en Repera.';
  }
  if(action==='chat-send'){
   await auth.sendChatMessage({orgId:selectedOrg,clientId:data.get('client'),body:data.get('body')});
   chatMessages=await auth.listThread({orgId:selectedOrg,clientId:data.get('client')})||[];
   clientSection='chat';selectedClientId=data.get('client');
   notice='Mensaje enviado.';
  }
  if(action==='chat-broadcast'){
   const scope=data.get('scope');
   const body=data.get('body');
   const picked=[...f.querySelectorAll('input[name="clients"]:checked')].map(n=>n.value);
   if(scope==='all')await auth.sendBroadcast({orgId:selectedOrg,body,allActive:true});
   else if(scope==='occurrence'){
    if(!data.get('occurrence'))throw Error('Elige una clase o cita.');
    await auth.sendBroadcast({orgId:selectedOrg,body,occurrenceId:data.get('occurrence')});
   }else if(scope==='group'){
    if(!data.get('group'))throw Error('Elige un grupo.');
    await auth.sendBroadcast({orgId:selectedOrg,body,groupId:data.get('group')});
   }else{
    if(!picked.length)throw Error('Selecciona al menos un cliente.');
    await auth.sendBroadcast({orgId:selectedOrg,body,clientIds:picked});
   }
   businessDialog='';
   notice='Aviso enviado a los destinatarios elegidos.';
  }
  if(action==='trainer-attendance'){
   const attendClient=passes.find(p=>p.id===data.get('pass'))?.client_id||data.get('client');
   await auth.recordTrainerAttendance({orgId:selectedOrg,
     clientId:attendClient,
     passId:data.get('pass'),occurrenceId:data.get('occurrence')||null,note:data.get('note')||''});
   if(attendClient){selectedClientId=attendClient;clientSection='passes';}
   await loadSelectedOrg();businessDialog='';notice='Sesión realizada registrada. Se ha descontado un crédito solo si no había reserva ya descontada.';
  }
  if(action==='create-pass-offer'||action==='update-pass-offer'){
    const billing=data.get('billing')||'session_pack';
    let credits=1,validityDays=30,price=0;
    let accessScope='trainer_appointments';
    let slotWeekdays=[1,2,3,4,5],slotStartMinute=540,slotEndMinute=720;
    if(billing==='session_pack'){
     credits=Number(data.get('credits'));
     validityDays=Number(data.get('validityDays'));
     price=Number(data.get('price'));
    }else if(billing==='monthly'){
     credits=9999;
     validityDays=Number(data.get('validityDaysMonthly')||30);
     price=Number(data.get('priceMonthly'));
    }else if(billing==='unlimited'){
     credits=9999;
     validityDays=Number(data.get('validityDaysUnlimited')||365);
     price=Number(data.get('priceUnlimited'));
    }else if(billing==='time_slot'){
     credits=9999;
     validityDays=Number(data.get('validityDaysSlot')||90);
     price=Number(data.get('priceSlot'));
     accessScope=data.get('accessScope')==='gym_access'?'gym_access':'trainer_appointments';
     slotWeekdays=Array.isArray(passOfferSlots)?passOfferSlots:[];
     if(!slotWeekdays.length)throw Error('Elige al menos un día de la franja.');
     slotStartMinute=timeToMinute(data.get('slotStart')||'09:00');
     slotEndMinute=timeToMinute(data.get('slotEnd')||'12:00');
     if(slotEndMinute<=slotStartMinute)throw Error('La hora «Hasta» debe ser posterior a «Desde».');
    }
    const kind=accessScope==='gym_access'?'class'
     :(data.get('kind')==='class'?'class':'appointment');
    // Fuera de franja horaria, el alcance sigue al kind (evita PASS_OUTSIDE_SLOT en clases).
    if(billing!=='time_slot'){
     accessScope=kind==='class'?'gym_access':'trainer_appointments';
    }
    if(action==='update-pass-offer'){
     await auth.updateServicePassOffer({
      id:data.get('id'),name:data.get('name'),kind,credits,validityDays,
      priceCents:Math.round(price*100),isActive:data.get('isActive')!=='false',
      billingModel:billing,accessScope,slotWeekdays,slotStartMinute,slotEndMinute,
     });
     selectedOfferId='';businessDialog='';
     await loadSelectedOrg();notice='Plan actualizado. El cobro sigue siendo externo a Repera.';
    }else{
     await auth.createServicePassOffer({
      orgId:selectedOrg,name:data.get('name'),kind,credits,validityDays,
      priceCents:Math.round(price*100),billingModel:billing,accessScope,
      slotWeekdays,slotStartMinute,slotEndMinute,
     });
     businessDialog='';
     await loadSelectedOrg();notice='Plan publicado. El cobro sigue siendo externo a Repera.';
    }
  }
  if(action==='quick-workout'){
   const mode=data.get('mode')||'day';
   const start=data.get('date');
   const clientId=data.get('client');
   const title=String(data.get('title')||'Entreno').trim();
   const exercises=[...f.querySelectorAll('[data-quick-ex]')].map(card=>{
    const id=card.dataset.id||'custom';
    const known=MOVEMENTS.find(m=>m.id===id);
    const name=card.dataset.name||known?.name||'Ejercicio';
    return {
     id,name,
     sets:Number(card.querySelector('[data-q-sets]')?.value||3),
     reps:Number(card.querySelector('[data-q-reps]')?.value||8),
     rir:Number(card.querySelector('[data-q-rir]')?.value||2),
     weight:Number(card.querySelector('[data-q-weight]')?.value||0),
     duration:0,notes:'',
    };
   });
   if(!exercises.length)throw Error('Añade al menos un movimiento desde la biblioteca.');
   const prescription=canonicalPrescription(validatePrescription({version:1,blocks:[{kind:'strength',format:data.get('format')||'sets',title:'Fuerza',rounds:1,timeCap:0,exercises}]}));
   const weekdays=[...f.querySelectorAll('input[name="weekdays"]:checked')].map(x=>Number(x.value));
   const weeks=Math.min(Math.max(Number(data.get('weeks')||4),1),8);
   let end=String(data.get('end')||start);
   if(mode==='weekly'){
    const d=new Date(start+'T12:00:00');d.setDate(d.getDate()+(weeks*7)-1);
    end=d.toLocaleDateString('sv-SE');
   }
   if(mode==='day'){
    await auth.publishProfessionalSession({orgId:selectedOrg,clientId,date:start,title,instructions:data.get('instructions')||'',prescription});
    notice='Entreno programado.';
   }else{
    if(!weekdays.length)throw Error('Marca al menos un día de la semana.');
    const n=countQuickWorkoutSessions({mode,start,end,weeks,weekdays});
    if(!n)throw Error('No hay días de entreno en ese rango.');
    if(n>120)throw Error('Demasiadas sesiones (máx. 120). Acorta el plan.');
    const result=await auth.bulkPublishCustomTraining({
     orgId:selectedOrg,clientIds:[clientId],start,end,weekdays,
     title,instructions:data.get('instructions')||'',prescription,
     requestId:crypto.randomUUID()});
    notice=`Plan publicado: ${result.created||0} sesiones`+(result.skipped?` · ${result.skipped} ya existían`:'')+'.';
   }
   businessDialog='';await loadSelectedOrg();
  }
  if(action==='courtesy-pass'){
   await auth.grantCourtesyPass({orgId:selectedOrg,clientId:data.get('client'),kind:data.get('kind'),credits:Number(data.get('credits')),validUntil:data.get('until')+'T23:59:59'});
   selectedClientId=data.get('client');clientSection='passes';businessDialog='';
   await loadSelectedOrg();notice='Bono de cortesía registrado, sin cobro.';
  }
  if(action==='client'){
   const clientName=inviteDraft.name||String(data.get('name')||'').trim();
   const clientEmail=inviteDraft.email||String(data.get('email')||'').trim().toLowerCase();
   const clientPhone=inviteDraft.phone||String(data.get('phone')||'').trim();
   const passMode=inviteDraft.passMode||String(data.get('passMode')||'none');
   const orgRow=organizations.find(o=>o.id===selectedOrg);
   if(passMode==='paid'&&data.get('confirmed')!=='yes'){
    inviteEmailError='';
    error='Confirma que has cobrado fuera de Repera para asignar el bono.';
    showInviteModal=true;return;
   }
   let result=null;
   try{
    const paidRaw=inviteDraft.paidAmount||data.get('paidAmount');
    const paidAmountCents=paidRaw===''||paidRaw==null?null:Math.round(Number(paidRaw)*100);
    result=await auth.inviteAthleteClient({
     orgId:selectedOrg,name:clientName,email:clientEmail,phone:clientPhone,
     passMode,
     trialCredits:passMode==='trial'?Number(inviteDraft.trialCredits||data.get('trialCredits')||3):null,
     trialKind:passMode==='trial'?(inviteDraft.trialKind||data.get('trialKind')||null):null,
     trialDays:passMode==='trial'?Number(inviteDraft.trialDays||data.get('trialDays')||30):30,
     offerId:passMode==='paid'?(inviteDraft.offerId||data.get('offer')||null):null,
     paymentMethod:passMode==='paid'?(inviteDraft.paymentMethod||data.get('paymentMethod')||'cash'):'cash',
     paidAmountCents:passMode==='paid'?paidAmountCents:null,
     paymentNote:passMode==='paid'?(inviteDraft.paymentNote||data.get('paymentNote')||''):'',
     passRequest:passMode==='paid'?(crypto.randomUUID?.()||null):null,
    });
   }catch(e){
    const under=inviteEmailIssue(e.message||e.code||'');
    showInviteModal=true;
    if(under){
     inviteEmailError=under;
     error='';notice='';
     return;
    }
    throw e;
   }
   const invitationId=asUuid(result?.invitation_id||result?.invitationId);
   const clientId=asUuid(result?.client_id||result?.clientId);
   const waWin=beginInvitationWhatsappPopup(orgRow);
   let delivery={sent:false,reason:'Invitación sin enviar'};
   if(invitationId){
    lastInviteShare={invitationId,email:clientEmail,sent:false,reason:'',clientName,clientPhone};
    try{
     delivery=await auth.sendInvitationEmail(invitationId);
     lastInviteShare.sent=!!delivery.sent;
     lastInviteShare.reason=delivery.reason||'';
    }catch(e){
     delivery={sent:false,reason:e.message||'Envío no confirmado'};
     lastInviteShare.reason=delivery.reason;
    }
   }
   clients=await auth.clients(selectedOrg).catch(()=>clients);
   invitations=await soft('invitations',auth.invitations(),invitations);
   if(passMode!=='none')passes=await soft('passes',auth.servicePasses(selectedOrg),passes);
   const created=clients.find(c=>c.id===clientId)
    ||clients.find(c=>String(c.email||'').toLowerCase()===clientEmail);
   showInviteModal=false;
   inviteEmailError='';
   inviteDraft={name:'',email:'',phone:''};
   selectedClientId=created?.id||clientId||null;
   clientSection=passMode==='none'?'data':'passes';
   activeTab='clients';
   businessDialog='';
   const wa=finishInvitationWhatsappPopup(waWin,{org:orgRow,clientName,clientPhone,invitationId});
   const passBit=passMode==='trial'?' · prueba lista':passMode==='paid'?' · bono asignado':'';
   if(wa)notice='WhatsApp abierto'+passBit;
   else if(delivery.sent)notice='Invitación enviada'+passBit;
   else if(invitationId)notice=(result?.reused?'Invitación renovada':'Enlace app en la ficha')+passBit;
   else notice='Ficha creada · sin invitación';
  }
  if(action==='rename'){
    const orgId=data.get('id');
    const pending=[];
    await auth.renameOrganization(orgId,data.get('name'));
    await auth.updateOrganizationBranding({orgId,tagline:data.get('tagline'),isDiscoverable:data.get('discoverable')==='on'});
    // Foto primero / aislada: no debe fallar por permisos de organization_legal_profiles.
    if(data.get('avatarFile')?.size){
     try{await auth.uploadBrandImage({orgId,kind:organizations.find(o=>o.id===orgId)?.kind,file:data.get('avatarFile')});}
     catch(e){pending.push('imagen ('+(e.message||'error')+')');}
    }
    await reload();
    notice=pending.length?'Identidad actualizada con avisos: '+pending.join(', '):'Identidad visual actualizada.';
   }
  if(action==='operation-settings'){
   const profile=data.get('profile')||'gym_multi';
   const defaults=profileDefaults(profile);
   await auth.upsertOrgOperationSettings(selectedOrg,{
    profile,
    use_rooms:data.get('use_rooms')==='on',
    day_program_enabled:data.get('day_program_enabled')==='on',
    day_program_scope:data.get('day_program_scope')||defaults.day_program_scope,
    open_access_enabled:data.get('open_access_enabled')==='on',
    open_access_requires_booking:data.get('open_access_requires_booking')==='on',
    cancel_credit_hours:Number(data.get('cancel_credit_hours')??defaults.cancel_credit_hours),
   });
   const hours=Number(data.get('class_booking_open_hours')||168);
   if(Number.isFinite(hours))await auth.updateOrgBookingWindow({orgId:selectedOrg,hours});
   await loadSelectedOrg();
   organizations=await soft('organizations',auth.organizations(),organizations);
   settingsSection='operation';activeTab='settings';
   notice='Ajustes de operación guardados.';
  }
  if(action==='upsert-room'){
   await auth.upsertFacilityRoom({
    orgId:selectedOrg,
    id:data.get('id')||null,
    name:data.get('name'),
    capacity:Number(data.get('capacity')||20),
    isActive:data.get('is_active')==='on',
   });
   await loadSelectedOrg();
   settingsSection='operation';activeTab='settings';
   notice='Sala guardada.';
  }
  if(action==='upsert-activity-type'){
   await auth.upsertActivityType({
    orgId:selectedOrg,
    id:data.get('id')||null,
    code:data.get('code'),
    name:data.get('name'),
    color:data.get('color')||'#22834d',
    supportsDayProgram:data.get('supports_day_program')==='on',
    isOpenAccess:data.get('is_open_access')==='on',
   });
   await loadSelectedOrg();
   settingsSection='operation';activeTab='settings';
   notice='Tipo de actividad guardado.';
  }
  if(action==='upsert-day-program'){
   await auth.upsertDayProgram({
    orgId:selectedOrg,
    date:data.get('program_date'),
    scope:data.get('scope')||'global',
    activityTypeId:data.get('activity_type_id')||null,
    roomId:data.get('room_id')||null,
    title:data.get('title')||'',
    instructions:data.get('instructions')||'',
    prescription:null,
   });
   notice='Programa del día guardado.';
  }
  if(action==='settings'){
    const values=Object.fromEntries(data.entries());
    const pending=[];
    await auth.updateOrganization({orgId:selectedOrg,name:data.get('name'),publicValues:values});
    // Subir foto antes del bloque fiscal: el permiso denegado de legal_profiles
    // no debe impedir guardar el logotipo / foto del entrenador.
    if(data.get('avatarFile')?.size){
     try{await auth.uploadBrandImage({orgId:selectedOrg,kind:organizations.find(o=>o.id===selectedOrg)?.kind,file:data.get('avatarFile')});}
     catch(e){pending.push('imagen ('+(e.message||'error')+')');}
    }
    try{await auth.upsertLegalProfile(selectedOrg,values);}
    catch(e){pending.push('datos fiscales ('+(e.message||'error')+')');}
    await reload();
    notice=pending.length
     ?'Perfil guardado con avisos: '+pending.join(', ')
     :'Perfil y datos legales actualizados.';
   }
  if(action==='whatsapp-connect'){
   const digits=parseWhatsappE164(whatsappDraft||data.get('whatsapp'));
   if(!digits)throw Error('Número de WhatsApp inválido. Usa prefijo país, p. ej. +34600111222.');
   const wasConnected=Boolean(organizations.find(o=>o.id===selectedOrg)?.whatsapp_e164);
   const updated=await auth.connectOrgWhatsapp({orgId:selectedOrg,e164:digits});
   whatsappDraft=null;
   if(updated?.id){
    organizations=organizations.map(o=>o.id===updated.id?{...o,...updated}:o);
   }else{
    organizations=await soft('organizations',auth.organizations(),organizations);
   }
   settingsSection='services';activeTab='settings';
   notice=wasConnected?'WhatsApp actualizado':'WhatsApp conectado';
  }
  if(action==='booking-window'){
   const hours=Number(data.get('hours')||168);
   await auth.updateOrgBookingWindow({orgId:selectedOrg,hours});
   organizations=await soft('organizations',auth.organizations(),organizations);
   settingsSection='services';activeTab='settings';
   notice='Antelación de inscripción guardada.';
  }
  if(action==='whatsapp-invite'){
   const invitationId=data.get('invitation');
   if(!/^[0-9a-f-]{36}$/i.test(invitationId||''))throw Error('Invitación inválida');
   const orgRow=organizations.find(o=>o.id===selectedOrg);
   const win=beginInvitationWhatsappPopup(orgRow)||window.open('about:blank','_blank');
   finishInvitationWhatsappPopup(win,{
    org:orgRow,
    clientName:data.get('clientName')||'',
    clientPhone:data.get('toPhone')||'',
    invitationId,
   });
   notice='WhatsApp abierto';
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
  }else{
   user=await auth.currentUser();
   if(user){
    try{
     await reload();
     await finalizePendingRegistration();
    }catch(e){
     // No tirar la sesión por un RPC/datos fallidos: solo por auth real.
     if(e.status===401||e.status===403){
      auth.clear();user=null;
      error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';
     }else{
      error=e.message||'No se pudieron cargar todos los datos. Prueba a recargar.';
     }
    }
   }
  }
 }catch(e){
  if(e.status===401||e.status===403||!auth.session){
   auth.clear();user=null;
   error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';
  }else{
   error=e.message||'No se ha podido iniciar la consola.';
  }
 }
 finally{busy=false;render();}
}
boot();
