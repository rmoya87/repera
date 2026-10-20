import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
import {renderServicesPanel} from './connected-services.js';
import {renderProfessionalPlanning} from './connected-planning.js';
import {navIcon} from './nav-icons.js';
import {renderBusinessHome,renderClient360,renderClasses360} from './management-360.js';
import {handleEditorClick,handleEditorSearch,readPrescription,validatePrescription} from './workout-editor.js';
const app=document.querySelector('#app');
const auth=new ReperaAuthAPI({baseUrl:SUPABASE_URL,publishableKey:SUPABASE_PUBLISHABLE_KEY});
const escapeHTML=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let user=null,organizations=[],memberships=[],invitations=[],clients=[],occurrences=[],passes=[],bookings=[],professionalSessions=[],templates=[],selectedOrg=null,trialRows=[],classDetails=[],groups=[],notices=[],selectedClientId=null,selectedClassId=null,classMode='calendar',calendarMonth='',planningClientId=null,activeTab='overview',selectedTemplateId=null,editingSessionId=null,view='login',busy=false,error='',notice='';
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador independiente',sports_center:'Centro deportivo'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
const message=()=>`${error?`<p class="connected-error" role="alert">${escapeHTML(error)}</p>`:''}${notice?`<p class="connected-notice" role="status">${escapeHTML(notice)}</p>`:''}`;
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname;

const PRICING={
 personal_trainer:[['trainer_5','Inicio',14,'Hasta 5 clientes'],['trainer_50','Profesional',50,'Hasta 50 clientes'],['trainer_75','Crecimiento',65,'Hasta 75 clientes']],
 gym:[['gym_basic','Básico',34,'Hasta 35 usuarios'],['gym_advanced','Avanzado',44,'Hasta 70 usuarios'],['gym_expert','Experto',54,'Usuarios ilimitados']],
 sports_center:[['gym_basic','Básico',34,'Hasta 35 usuarios'],['gym_advanced','Avanzado',44,'Hasta 70 usuarios'],['gym_expert','Experto',54,'Usuarios ilimitados']]
};
function trialStatus(){
 const rec=trialRows[0];if(!rec)return {active:false,days:0};
 const ms=new Date(rec.trial_ends_at)-Date.now();
 const paid=rec.paid_plan&&rec.paid_until&&new Date(rec.paid_until)>new Date();
 return {active:paid||ms>0,paid,days:Math.max(0,Math.ceil(ms/86400000)),rec};
}
function renderSubscriptions(org){
 const state=trialStatus(),trial=state.rec;
 const head=state.paid?`Plan ${escapeHTML(trial.paid_plan)} activo`:state.active?`Prueba gratuita · ${state.days} días restantes`:'Prueba finalizada · elige un plan';
 const rows=(PRICING[org.kind]||PRICING.gym).map(([key,title,price,capacity])=>`<article class="business-price"><h3>${title}</h3><strong>${price} €<small> / mes</small></strong><p>${capacity}</p>${org.kind!=='personal_trainer'?'<p>Oferta introductoria de 2 meses; precio posterior pendiente de definir.</p>':''}<button type="button" class="connected-secondary" data-action="choose-plan" data-plan="${key}">Seleccionar</button></article>`).join('');
 return `<section class="connected-card business-subscriptions"><span class="connected-tag">SUSCRIPCIÓN</span><h2>${head}</h2><p>No se cobrará nada ni se activará un plan de pago hasta integrar un proveedor verificado. Seleccionar registra únicamente tu interés.</p><div class="business-prices">${rows}</div></section>`;
}
function enhanceWorkspace(own){
 const root=app.querySelector('.connected-workspace');if(!root)return;
 root.querySelector('.connected-next')?.remove();
 const org=organizations.find(o=>o.id===selectedOrg);
 const kind=org?.kind,trainer=kind==='personal_trainer',manager=['owner','admin'].includes(own.get(selectedOrg));
 const tabs=org?[['overview','Inicio','dashboard'],['clients','Clientes','clients'],['planning','Entrenamientos','planning'],['services',trainer?'Citas y reservas':'Clases y reservas','calendar'],['bonos','Bonos y tarifas','products'],['billing','Facturación','billing'],['analytics','Analíticas','analytics'],...(trainer?[]:[['team','Equipo y espacios','team']]),['settings','Configuración','settings']]:[['overview','Inicio','dashboard']];
 if(!tabs.some(t=>t[0]===activeTab))activeTab='overview';
 const nav=document.createElement('nav');nav.className='business-navigation';nav.setAttribute('aria-label','Menú profesional');
 nav.innerHTML=tabs.map(([id,label,icon])=>`<button type="button" data-workspace="${id}" aria-current="${activeTab===id?'page':'false'}">${navIcon(icon)}${escapeHTML(label)}</button>`).join('');
 const picker=document.createElement('label');picker.className='connected-field';picker.style.cssText='margin-left:auto;min-width:160px;max-width:240px';
 picker.innerHTML=`<span class="sr-only">Organización activa</span><select id="workspace-org-select"><option value="">Selecciona un negocio</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${o.id===selectedOrg?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select>`;
 nav.append(picker);
 root.querySelector('.connected-heading')?.insertAdjacentElement('afterend',nav);
 if(!org)return;
 root.querySelector('.connected-heading h1').textContent=org.name;
 // El panel legado no se utiliza como ficha ni agenda de operaciones.
 root.querySelector('.connected-grid')?.remove();
 root.querySelector('[data-workspace-section="clients"]')?.remove();
 root.querySelector('[data-workspace-section="services"]')?.remove();
 const attach=(tab,html)=>{const node=document.createElement('div');node.dataset.workspaceSection=tab;node.innerHTML=html;root.append(node);};
 attach('overview',renderBusinessHome({org,clients,occurrences,bookings,sessions:professionalSessions,templates}));
 attach('clients',renderClient360({clients,selected:selectedClientId,passes,bookings,occurrences,sessions:professionalSessions,notices,manager,role:own.get(selectedOrg)}));
 const members=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'&&['owner','admin','coach'].includes(m.role)).map(m=>({user_id:m.user_id,label:m.user_id===user.id?'Mi cuenta':'Profesional '+m.user_id.slice(0,8)}));
 attach('services',renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,coaches:members,selected:selectedClassId,listMode:classMode,calendarMonth,manager}));
 attach('bonos',`<section class="connected-card"><h2>Bonos y tarifas</h2><p>Bonos reales de cortesía y saldos verificados en Supabase. Los cobros y renovaciones de pago siguen pendientes de integración.</p>${passes.map(p=>`<article class="connected-org"><strong>${escapeHTML(clients.find(c=>c.id===p.client_id)?.name||'Cliente')} · ${p.kind==='class'?'Clase':'Cita'}</strong><small>${p.remaining_credits} de ${p.total_credits} disponibles</small></article>`).join('')||'<p>No hay bonos todavía.</p>'}</section>`);
 attach('billing',`<section class="connected-card"><h2>Facturación</h2><p>La pasarela de pago y la facturación legal todavía no están habilitadas. No se muestran cobros simulados como reales.</p></section>`);
 attach('analytics',`<section class="connected-card"><h2>Analíticas del negocio</h2><div class="business-stats"><div class="business-stat"><span>Clientes</span><strong>${clients.length}</strong></div><div class="business-stat"><span>Reservas activas</span><strong>${bookings.filter(b=>b.status==='booked').length}</strong></div><div class="business-stat"><span>Sesiones programadas</span><strong>${occurrences.filter(o=>o.status==='active').length}</strong></div></div><p>Las métricas deportivas personales solo estarán disponibles con consentimiento y sincronización del atleta.</p></section>`);
 const settings=document.createElement('section');settings.className='connected-card connected-settings';settings.dataset.workspaceSection='settings';
 settings.innerHTML=`<span class="connected-tag">DATOS DEL ${trainer?'PROFESIONAL':'NEGOCIO'}</span><h2>Configuración de ${escapeHTML(org.name)}</h2><p>Solo propietarios o administradores pueden modificar los datos del negocio.</p><form data-connected="settings" class="settings-grid">
 <label class="connected-field">Nombre comercial<input name="name" maxlength="120" minlength="2" value="${escapeHTML(org.name)}" required ${!manager?'disabled':''}></label>
 <label class="connected-field">Email público<input name="publicEmail" type="email" maxlength="180" value="${escapeHTML(org.public_email||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field">Teléfono<input name="phone" maxlength="40" value="${escapeHTML(org.phone||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field">Sitio web<input name="website" type="url" maxlength="255" value="${escapeHTML(org.website||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field full">Dirección<input name="address" maxlength="300" value="${escapeHTML(org.address||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field full">Descripción<textarea name="description" rows="3" maxlength="2000" ${!manager?'disabled':''}>${escapeHTML(org.description||'')}</textarea></label>
 <label class="connected-field">Zona horaria<input name="timezone" maxlength="80" required value="${escapeHTML(org.timezone||'Europe/Madrid')}" ${!manager?'disabled':''}></label>
 <div class="full"><strong>Perfil:</strong> ${escapeHTML(kindLabel[kind]||kind)}</div>
 ${manager?'<button class="connected-primary" type="submit">Guardar datos</button>':''}</form>`;
 root.append(settings);
 attach('settings',renderSubscriptions(org));
 // Centro y entrenador disponen de permisos diferentes; ocultar equipo al autónomo.
 if(trainer)root.querySelector('[data-workspace-section="team"]')?.remove();
 const trial=trialStatus();
 if(!trial.active&&activeTab!=='settings'){
  const notice=document.createElement('div');notice.className='connected-error';notice.innerHTML='<strong>Prueba finalizada.</strong> Para seguir administrando el negocio, elige un plan en Configuración. Los pagos todavía no están disponibles.';
  nav.insertAdjacentElement('afterend',notice);
 }
 root.querySelectorAll('[data-workspace-section]').forEach(el=>{el.style.display=el.dataset.workspaceSection===activeTab?'':'none';});
}function render(){
 const common=`<header class="connected-header"><div class="brand"><span class="brand-symbol">R</span><span><strong>repera</strong><small>Business</small></span></div><a href="?demo=1" class="connected-demo">Abrir demostración local ↗</a></header>`;
 if(!user){
  const title={login:'Accede a tu negocio',register:'Crear cuenta profesional',recover:'Recuperar acceso',password:'Establecer nueva contraseña'}[view];
  const form=view==='login'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='register'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Crear cuenta</button>`
   :view==='recover'
   ?`${field('Correo electrónico','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Actualizar contraseña</button>`;
  app.innerHTML=`<div class="connected-page">${common}<main class="connected-auth"><div class="connected-card"><span class="connected-tag">PLATAFORMA PROFESIONAL</span><h1>${title}</h1><p class="connected-intro">Gestión real de organizaciones mediante Supabase. Tus entrenamientos personales permanecen en la app nativa.</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver a iniciar sesión</button>':''}${view==='login'?'<button type="button" data-view="register">Crear cuenta</button><button type="button" data-view="recover">Olvidé mi contraseña</button>':''}</div></div></main></div>`;
  return;
 }
 const pendingInvites=invitations.filter(i=>!i.accepted_at&&!i.cancelled_at&&new Date(i.expires_at).getTime()>Date.now());
 const ownInvites=pendingInvites.filter(i=>i.email===(user.email||'').trim().toLowerCase());
 const own=new Map(memberships.filter(m=>m.user_id===user.id&&m.status==='active').map(m=>[m.organization_id,m.role]));
 app.innerHTML=`<div class="connected-page">${common}<main class="connected-workspace"><div class="connected-heading"><div><span class="connected-tag">SESIÓN AUTENTICADA · SUPABASE REPERA</span><h1>Mis organizaciones</h1><p>${escapeHTML(user.email||'Cuenta Repera')} · Solo se muestran negocios autorizados por la base de datos.</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button></div>${message()}${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}<section data-workspace-section="overview" class="connected-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div>${['owner','admin'].includes(own.get(o.id))?`<form data-connected="rename" class="connected-inline"><input type="hidden" name="id" value="${escapeHTML(o.id)}"><label>Nombre<input name="name" value="${escapeHTML(o.name)}" maxlength="120" required></label><button class="connected-secondary" ${busy?'disabled':''}>Guardar</button></form>`:''}</article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card"><h2>Añadir organización</h2><p>Al crearla, Supabase te asigna el rol de propietario de forma segura.</p><form data-connected="create">${field('Nombre comercial','name','text','minlength="2" maxlength="120"')}${field('Identificador URL (minúsculas y guiones)','slug','text','minlength="3" maxlength="63" pattern="[a-z0-9][a-z0-9-]{2,62}"')}<label class="connected-field">Tipo<select name="kind"><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option><option value="sports_center">Centro deportivo</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear organización</button></form></div></section><section class="connected-card" data-workspace-section="clients" style="margin-top:22px"><h2>Clientes reales</h2><label class="connected-field">Organización<select id="connected-org-select"><option value="">Selecciona una organización</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${selectedOrg===o.id?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select></label>${selectedOrg?`<div style="margin-top:20px">${clients.length?clients.map(c=>`<article class="connected-org"><div><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email)} · ${escapeHTML(c.status)}</small></div></article>`).join(''):'<p>Sin clientes registrados en esta organización.</p>'}${['owner','admin'].includes(own.get(selectedOrg))?`<form data-connected="client">${field('Nombre del cliente','name','text','minlength="2" maxlength="120"')}${field('Correo electrónico','email','email')}<button class="connected-primary">Añadir cliente potencial</button></form>`:''}</div>`:''}</section>${selectedOrg&&["owner","admin"].includes(own.get(selectedOrg))?`<section class="connected-card" data-workspace-section="team" style="margin-top:22px"><h2>Invitar a mi organización</h2><p>La persona debe registrarse con el mismo correo verificado. Podrá aceptar la invitación al iniciar sesión. Aún no se envían correos automáticos.</p><form data-connected="invite">${field('Correo del invitado','email','email')}<label class="connected-field">Perfil<select name="role"><option value="athlete">Deportista</option><option value="coach">Entrenador</option><option value="reception">Recepción</option><option value="admin">Administrador</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button></form>${pendingInvites.filter(i=>i.organization_id===selectedOrg).length?`<p>Invitaciones pendientes: ${pendingInvites.filter(i=>i.organization_id===selectedOrg).length}</p>`:''}</section>`:''}${renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients,memberships,busy,escapeHTML,templateId:selectedTemplateId,sessionId:editingSessionId})}<div data-workspace-section="services">${renderServicesPanel({selectedOrg,role:own.get(selectedOrg),occurrences,passes,bookings,clients,memberships,busy,escapeHTML})}</div><section class="connected-next"><h2>Próximos módulos</h2><p>Asignación operativa de entrenadores, planes publicados, compra de bonos y reservas desde las apps móviles aún no están conectados. No se muestran datos ficticios en este espacio autenticado.</p><a href="?demo=1">Explorar funciones en la demostración (sin datos reales)</a></section></main></div>`;
 enhanceWorkspace(own);
}
async function loadSelectedOrg(){
 if(!selectedOrg){clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];trialRows=[];classDetails=[];groups=[];notices=[];return;}
 [clients,occurrences,passes,bookings,professionalSessions,templates,trialRows,classDetails,groups,notices]=await Promise.all([
 auth.clients(selectedOrg),auth.serviceOccurrences(selectedOrg),auth.servicePasses(selectedOrg),
 auth.serviceBookings(selectedOrg),auth.professionalSessions(selectedOrg),auth.workoutTemplates(selectedOrg),
 auth.organizationTrial(selectedOrg),auth.classDetails(selectedOrg),auth.groupList(selectedOrg),auth.clientNotifications(selectedOrg)]);
}
async function reload(){
 const [orgs,members,invites]=await Promise.all([auth.organizations(),auth.memberships(),auth.invitations()]);
 organizations=orgs||[];memberships=members||[];invitations=invites||[];
 if(!organizations.some(o=>o.id===selectedOrg))selectedOrg=organizations[0]?.id||null;
 await loadSelectedOrg();
}
app.addEventListener('click',async event=>{
 if(handleEditorClick(event))return;
 const tab=event.target.closest('[data-workspace]');if(tab){activeTab=tab.dataset.workspace;render();return;}
 const mode=event.target.closest('[data-view]');if(mode){view=mode.dataset.view;error=notice='';render();return;}
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 if(action==='detail-client'){selectedClientId=actionable.dataset.id;activeTab='clients';render();return;}
 if(action==='back-clients'){selectedClientId=null;activeTab='clients';render();return;}
 if(action==='detail-occurrence'){selectedClassId=actionable.dataset.id;activeTab='services';render();return;}
 if(action==='back-classes'){selectedClassId=null;activeTab='services';render();return;}
 if(action==='open-class-calendar'){selectedClassId=null;classMode='calendar';activeTab='services';render();return;}
 if(action==='calendar-mode'){classMode=actionable.dataset.mode==='list'?'list':'calendar';render();return;}
 if(action==='calendar-prev'||action==='calendar-next'){
  const first=(calendarMonth?new Date(calendarMonth+'-01T12:00:00'):new Date());
  first.setDate(1);first.setMonth(first.getMonth()+(action==='calendar-next'?1:-1));
  calendarMonth=first.toLocaleDateString('sv-SE').slice(0,7);render();return;
 }
 if(action==='plan-client'){planningClientId=actionable.dataset.id;activeTab='planning';selectedTemplateId=null;editingSessionId=null;render();return;}
 if(action==='find-class-for-client'){selectedClientId=actionable.dataset.id;selectedClassId=null;activeTab='services';classMode='list';notice='Selecciona una clase para inscribir a este deportista con un bono válido.';render();return;}
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
 if(action==='accept-invitation'&&!busy){busy=true;error=notice='';render();try{await auth.acceptInvitation(actionable.dataset.id);await reload();notice='Invitación aceptada. Tu relación con el centro ya consta en Supabase.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='logout'){busy=true;render();try{await auth.signOut();user=null;organizations=[];memberships=[];invitations=[];view='login';notice='Sesión cerrada';}catch(e){user=null;organizations=[];memberships=[];view='login';notice='Sesión local cerrada. No se pudo confirmar el cierre remoto.';}finally{busy=false;render();}}
});
app.addEventListener('input',event=>{handleEditorSearch(event);});
app.addEventListener('change',async event=>{if(!['connected-org-select','workspace-org-select'].includes(event.target.id))return;selectedOrg=event.target.value||null;activeTab='overview';selectedTemplateId=null;editingSessionId=null;error='';clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];
 if(selectedOrg){try{await loadSelectedOrg();}catch(e){error=e.message;}}
 render();});
app.addEventListener('submit',async event=>{
 const f=event.target.closest('form[data-connected]');if(!f)return;event.preventDefault();if(busy)return;
 const action=f.dataset.connected,data=new FormData(f),intent=event.submitter?.dataset.intent||'publish';
 let prescription=null;
 try{if(action==='publish-session')prescription=validatePrescription(readPrescription(f));}catch(e){error=e.message;notice='';render();return;}
 busy=true;error=notice='';render();
 try{
  if(action==='login'){user=await auth.signIn(data.get('email'),data.get('password'));await reload();}
  if(action==='register'){const result=await auth.signUp(data.get('email'),data.get('password'),redirectTo());if(result.confirmationRequired){view='login';notice='Consulta tu correo y confirma la cuenta antes de iniciar sesión.';}else{user=await auth.currentUser();await reload();}}
  if(action==='recover'){await auth.requestPasswordReset(data.get('email'),redirectTo());view='login';notice='Si la dirección existe, recibirás un enlace de recuperación.';}
  if(action==='password'){await auth.changePassword(data.get('password'));await auth.signOut();user=null;view='login';notice='Contraseña actualizada. Inicia sesión de nuevo.';}
  if(action==='create'){await auth.createOrganization({name:data.get('name'),slug:data.get('slug'),kind:data.get('kind'),userId:user.id});await reload();notice='Organización creada correctamente.';}
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
  if(action==='assign-coach'){
   await auth.assignCoachClient({orgId:selectedOrg,clientId:data.get('client'),coachId:data.get('coach')});
   await reload();notice='Entrenador asignado al cliente.';
  }
  if(action==='service-occurrence'){
   await auth.addServiceOccurrence({orgId:selectedOrg,coachId:data.get('coach'),kind:data.get('kind'),title:data.get('title'),start:data.get('start'),end:data.get('end'),capacity:Number(data.get('capacity'))});
   await reload();notice='Horario creado en Supabase.';
  }
  if(action==='courtesy-pass'){
   await auth.grantCourtesyPass({orgId:selectedOrg,clientId:data.get('client'),kind:data.get('kind'),credits:Number(data.get('credits')),validUntil:data.get('until')+'T23:59:59'});
   await reload();notice='Bono de cortesía registrado, sin cobro.';
  }
  if(action==='client'){await auth.addClient({orgId:selectedOrg,name:data.get('name'),email:data.get('email'),userId:user.id});clients=await auth.clients(selectedOrg);notice='Cliente potencial registrado.';}
  if(action==='rename'){await auth.renameOrganization(data.get('id'),data.get('name'));await reload();notice='Nombre actualizado.';}
  if(action==='settings'){await auth.updateOrganization({orgId:selectedOrg,name:data.get('name'),publicEmail:data.get('publicEmail'),phone:data.get('phone'),website:data.get('website'),address:data.get('address'),description:data.get('description'),timezone:data.get('timezone')});await reload();notice='Datos del negocio actualizados.';}
 }catch(e){error=e.message||'No se pudo completar la operación';}
 finally{busy=false;render();}
});
async function boot(){
 busy=true;render();
 try{
  if(await auth.acceptRecoveryFragment(globalThis.location?.hash||'')){
   history.replaceState(null,'',location.pathname+location.search);view='password';
   // Recovery JWT is valid; keep password screen rather than normal admin UI.
  }else{user=await auth.currentUser();if(user)await reload();}
 }catch(e){auth.clear();error='No se ha podido recuperar la sesión. Inicia sesión nuevamente.';}
 finally{busy=false;render();}
}
boot();
