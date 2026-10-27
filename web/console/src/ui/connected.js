import {SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY} from '../core/config.js';
import {ReperaAuthAPI} from '../core/auth.js';
import {renderServicesPanel} from './connected-services.js';
import {renderProfessionalPlanning} from './connected-planning.js';
import {navIcon} from './nav-icons.js';
import {renderBusinessHome,renderClient360,renderClasses360} from './management-360.js';
import {handleEditorClick,handleEditorSearch,readPrescription,validatePrescription,canonicalPrescription,emptyPrescription} from './workout-editor.js';
const app=document.querySelector('#app');
const auth=new ReperaAuthAPI({baseUrl:SUPABASE_URL,publishableKey:SUPABASE_PUBLISHABLE_KEY});
const escapeHTML=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let user=null,platformRole=null,platformOrgs=[],organizations=[],memberships=[],invitations=[],clients=[],occurrences=[],passes=[],bookings=[],professionalSessions=[],templates=[],selectedOrg=null,trialRows=[],classDetails=[],groups=[],groupMembers=[],notices=[],sharedHistory=[],selectedClientId=null,selectedClassId=null,selectedGroupId=null,classMode='calendar',calendarMonth='',classEditorId=null,planningClientId=null,activeTab='overview',selectedTemplateId=null,editingSessionId=null,view='login',busy=false,error='',notice='',businessDialog='',dialogDay='',settingsSection='profile';
const kindLabel={gym:'Gimnasio',personal_trainer:'Entrenador independiente',sports_center:'Centro deportivo'};
const roleLabel={owner:'Propietario',admin:'Administrador',coach:'Entrenador',reception:'Recepción',athlete:'Deportista'};
const message=()=>`${error?`<p class="connected-error" role="alert">${escapeHTML(error)}</p>`:''}${notice?`<p class="connected-notice" role="status">${escapeHTML(notice)}</p>`:''}`;
const field=(label,name,type='text',extra='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" autocomplete="${name==='email'?'email':name==='password'?'current-password':'off'}" required ${extra}></label>`;
const redirectTo=()=>location.origin+location.pathname;

function restoreWorkspaceRoute(){
 const query=new URLSearchParams(location.search);
 const section=query.get('seccion'),client=query.get('cliente'),org=query.get('espacio');
 if(org&&/^[0-9a-f-]{36}$/i.test(org))selectedOrg=org;
 if(['overview','clients','planning','services','bonos','billing','analytics','team','settings','platform'].includes(section))activeTab=section;
 if(client&&/^[0-9a-f-]{36}$/i.test(client)){selectedClientId=client;planningClientId=client;activeTab='clients';}
 else if(section==='clients'){selectedClientId=null;planningClientId=null;editingSessionId=null;selectedTemplateId=null;}
}
function setWorkspaceRoute(replace=false){
 const uri=new URL(location.href);
 uri.searchParams.set('seccion',activeTab);
 if(selectedOrg)uri.searchParams.set('espacio',selectedOrg);else uri.searchParams.delete('espacio');
 if(activeTab==='clients'&&selectedClientId)uri.searchParams.set('cliente',selectedClientId);
 else uri.searchParams.delete('cliente');
 history[replace?'replaceState':'pushState'](null,'',uri.pathname+uri.search+uri.hash);
}
function openBusinessDialog({org,manager,trainer,coaches}){
 if(!trainer||!businessDialog)return '';
 const iso=dialogDay||new Date().toLocaleDateString('sv-SE');
 const start=iso+'T10:00',end=iso+'T11:00';
 const selected=clients.find(c=>c.id===selectedClientId);
 const dialogHeader=businessDialog==='bulk'?'Añadir planificación':businessDialog==='new-appointment'?'Nueva cita o grupo':'Detalle de la sesión';
 let content='';
 if(businessDialog==='new-appointment')content=`<form data-connected="service-occurrence" class="business-form">
 <label class="connected-field">Tipo<select name="kind"><option value="appointment">Cita individual</option><option value="class">Grupo</option></select></label>
 <label class="connected-field">Título<input name="title" value="Sesión personal" maxlength="120" minlength="2" required></label>
 <label class="connected-field">Inicio<input name="start" type="datetime-local" value="${escapeHTML(start)}" required></label>
 <label class="connected-field">Fin<input name="end" type="datetime-local" value="${escapeHTML(end)}" required></label>
 <label class="connected-field">Aforo (en citas individuales siempre 1)<input name="capacity" type="number" min="1" max="200" value="1" required></label>
 <label class="connected-field">Entrenador<select name="coach">${coaches.map(m=>`<option value="${escapeHTML(m.user_id)}">${escapeHTML(m.label)}</option>`).join('')}</select></label>
 <input name="repeat" type="hidden" value="none"><input name="repeatCount" type="hidden" value="1">
 <p class="connected-hint">La cita queda guardada en la agenda. Puedes inscribir a la persona desde el detalle usando su bono válido.</p>
 <button class="connected-primary" type="submit" ${!manager?'disabled':''}>Crear en agenda</button></form>`;
 if(businessDialog==='bulk'){
  const linked=clients.filter(c=>c.user_id&&c.status==='active');
  content=`<form data-connected="bulk-plan" class="business-form">
  <p class="connected-hint">Programa un entrenamiento real para varios días y deportistas. Cada asignación se guarda por separado y se podrá modificar desde la ficha individual.</p>
  <strong>Deportistas</strong><div class="business-group-members">${linked.map(c=>`<label><input type="checkbox" name="clients" value="${escapeHTML(c.id)}" ${c.id===selectedClientId?'checked':''}><span class="business-avatar">${escapeHTML(c.name?.slice(0,1)||'•')}</span>${escapeHTML(c.name)}</label>`).join('')||'<p>Vincula primero un deportista activo.</p>'}</div>
  <div class="planning-form-row"><label class="connected-field">Desde<input name="from" type="date" min="${new Date().toLocaleDateString('sv-SE')}" value="${new Date().toLocaleDateString('sv-SE')}" required></label>
  <label class="connected-field">Hasta<input name="until" type="date" min="${new Date().toLocaleDateString('sv-SE')}" value="${new Date().toLocaleDateString('sv-SE')}" required></label></div>
  <label class="connected-field">Entrenamiento de referencia (opcional)<select name="template"><option value="">Sesión nueva sin plantilla</option>${templates.map(t=>`<option value="${escapeHTML(t.id)}">${escapeHTML(t.name)}</option>`).join('')}</select></label>
  <label class="connected-field">Título<input name="title" minlength="2" maxlength="120" value="" placeholder="Ej. Preparación de fuerza" required></label>
  <label class="connected-field">Indicaciones<textarea name="instructions" rows="3" maxlength="10000"></textarea></label>
  <p class="connected-hint">Se programa un entrenamiento por día natural y deportista seleccionado (máximo 60 asignaciones). No crea automáticamente citas ni consume bonos.</p>
  <button class="connected-primary" type="submit" ${!manager||!linked.length?'disabled':''}>Guardar planificación</button></form>`;
 }
 if(businessDialog==='occurrence')content=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches,selected:selectedClassId,classEditor:classEditorId===selectedClassId,manager});
 if(businessDialog==='group')content=renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,coaches,selectedGroup:selectedGroupId,manager});
 return `<div class="business-overlay" data-business-backdrop><section class="business-dialog" role="dialog" aria-modal="true" aria-label="${dialogHeader}"><div class="business-dialog-header"><h2>${dialogHeader}</h2><button type="button" data-action="close-business-dialog" class="icon-button" aria-label="Cerrar">×</button></div><div class="business-dialog-scroll">${content}</div></section></div>`;
}


const PRICING={
 personal_trainer:[['trainer_5','Inicio',14,'Hasta 5 clientes'],['trainer_50','Profesional',50,'Hasta 50 clientes'],['trainer_75','Crecimiento',65,'Hasta 75 clientes']],
 gym:[['gym_basic','Básico',39,'Hasta 35 usuarios'],['gym_advanced','Avanzado',69,'Hasta 70 usuarios'],['gym_expert','Experto',119,'Usuarios ilimitados · una sede']],
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
 const rows=(PRICING[org.kind]||PRICING.gym).map(([key,title,price,capacity])=>`<article class="business-price"><h3>${title}</h3><strong>${price} €<small> / mes + IVA</small></strong><p>${capacity}</p>${org.kind!=='personal_trainer'?'<p>Promoción de lanzamiento: 50 % durante 2 meses. Después se aplica el precio indicado; IVA no incluido.</p>':''}<button type="button" class="connected-secondary" data-action="choose-plan" data-plan="${key}">Seleccionar</button></article>`).join('');
 return `<section class="connected-card business-subscriptions"><span class="connected-tag">SUSCRIPCIÓN</span><h2>${head}</h2><p>Precios de referencia para una sede, sin IVA. En gimnasios proponemos un descuento del 50 % los dos primeros meses (el precio mostrado es el habitual). No se cobrará nada ni se activará un plan hasta integrar y validar la pasarela de pago. Seleccionar registra únicamente tu interés.</p><div class="business-prices">${rows}</div></section>`;
}
function enhanceWorkspace(own){
 const root=app.querySelector('.connected-workspace');if(!root)return;
 root.querySelector('.connected-next')?.remove();
 const org=organizations.find(o=>o.id===selectedOrg);
 const kind=org?.kind,trainer=kind==='personal_trainer',manager=['owner','admin'].includes(own.get(selectedOrg));
 const tabs=org?[['overview','Inicio','dashboard'],['clients','Clientes','clients'],...(trainer?[]:[['planning','Entrenamientos','planning'],['services','Clases y reservas','calendar']]),['bonos','Bonos y tarifas','products'],['billing','Facturación','billing'],['analytics','Analíticas','analytics'],...(trainer?[]:[['team','Equipo y espacios','team']]),['settings','Configuración','settings'],...(platformRole==='platform_admin'?[['platform','Administración Repera','admin']]:[])]:[['overview','Inicio','dashboard'],...(platformRole==='platform_admin'?[['platform','Administración Repera','admin']]:[])];
 if(!tabs.some(t=>t[0]===activeTab))activeTab='overview';
 const nav=document.createElement('nav');nav.className='business-navigation';nav.setAttribute('aria-label','Menú profesional');
 nav.innerHTML=tabs.map(([id,label,icon])=>`<button type="button" data-workspace="${id}" aria-current="${activeTab===id?'page':'false'}">${navIcon(icon)}${escapeHTML(label)}</button>`).join('');
 const picker=document.createElement('label');picker.className='connected-field';picker.style.cssText='margin-left:auto;min-width:160px;max-width:240px';
 picker.innerHTML=`<span class="sr-only">Organización activa</span><select id="workspace-org-select"><option value="">Selecciona un negocio</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${o.id===selectedOrg?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select>`;
 nav.append(picker);
 root.querySelector('.connected-heading')?.insertAdjacentElement('afterend',nav);
 if(!org){
  if(platformRole==='platform_admin'){
   const sec=document.createElement('section');sec.dataset.workspaceSection='platform';sec.className='connected-card';
   sec.innerHTML=`<h2>Administración Repera</h2><p>Consulta de negocios, sin acceso a historial privado.</p>${platformOrgs.map(o=>`<article class="connected-org"><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(o.kind)} · ${Number(o.client_count||0)} clientes</small></article>`).join('')||'<p>Sin organizaciones registradas.</p>'}`;
   root.append(sec);root.querySelectorAll('[data-workspace-section]').forEach(el=>el.style.display=el.dataset.workspaceSection===activeTab?'':'none');
  }
  return;
 }
 root.querySelector('.connected-heading h1').textContent=org.name;
 // El panel legado no se utiliza como ficha ni agenda de operaciones.
 root.querySelector('.connected-grid')?.remove();
 root.querySelector('[data-workspace-section="clients"]')?.remove();
 root.querySelector('[data-workspace-section="services"]')?.remove();
 const attach=(tab,html)=>{const node=document.createElement('div');node.dataset.workspaceSection=tab;node.innerHTML=html;root.append(node);};
 attach('overview',renderBusinessHome({org,clients,occurrences,bookings,sessions:professionalSessions,templates,calendarMonth}));
 attach('clients',renderClient360({clients,selected:selectedClientId,passes,bookings,occurrences,sessions:professionalSessions,notices,sharedHistory,manager,trainer,role:own.get(selectedOrg)})+(trainer&&selectedClientId?renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients,memberships,escapeHTML,busy,templateId:selectedTemplateId,sessionId:editingSessionId,clientId:selectedClientId,embedded:true}):''));
 const members=memberships.filter(m=>m.organization_id===org.id&&m.status==='active'&&['owner','admin','coach'].includes(m.role)).map(m=>({user_id:m.user_id,label:m.user_id===user.id?'Mi cuenta':'Profesional '+m.user_id.slice(0,8)}));
 if(!trainer)attach('services',renderClasses360({occurrences,clients,bookings,passes,details:classDetails,groups,groupMembers,selectedGroup:selectedGroupId,coaches:members,selected:selectedClassId,classEditor:classEditorId===selectedClassId,listMode:classMode,calendarMonth,manager}));
 attach('bonos',`<section class="connected-card"><h2>Bonos y tarifas</h2><p>Bonos reales de cortesía y saldos verificados en Supabase. Los cobros y renovaciones de pago siguen pendientes de integración.</p>${passes.map(p=>`<article class="connected-org"><strong>${escapeHTML(clients.find(c=>c.id===p.client_id)?.name||'Cliente')} · ${p.kind==='class'?'Clase':'Cita'}</strong><small>${p.remaining_credits} de ${p.total_credits} disponibles</small></article>`).join('')||'<p>No hay bonos todavía.</p>'}</section>`);
 attach('billing',`<section class="connected-card"><h2>Facturación</h2><p>La pasarela de pago y la facturación legal todavía no están habilitadas. No se muestran cobros simulados como reales.</p></section>`);
 attach('platform',`<section class="connected-card"><h2>Administración Repera</h2><p>Resumen de organizaciones de la plataforma. No permite acceder al historial privado de los deportistas ni suplantar cuentas.</p><div class="table-scroll"><table><thead><tr><th>Organización</th><th>Tipo</th><th>Clientes</th><th>Prueba finaliza</th></tr></thead><tbody>${platformOrgs.map(o=>`<tr><td>${escapeHTML(o.name)}</td><td>${escapeHTML(o.kind)}</td><td>${Number(o.client_count||0)}</td><td>${escapeHTML(o.trial_ends_at?.slice(0,10)||'—')}</td></tr>`).join('')||'<tr><td colspan="4">No hay organizaciones</td></tr>'}</tbody></table></div></section>`);
 attach('analytics',`<section class="connected-card"><h2>Analíticas del negocio</h2><div class="business-stats"><div class="business-stat"><span>Clientes</span><strong>${clients.length}</strong></div><div class="business-stat"><span>Reservas activas</span><strong>${bookings.filter(b=>b.status==='booked').length}</strong></div><div class="business-stat"><span>Sesiones programadas</span><strong>${occurrences.filter(o=>o.status==='active').length}</strong></div></div><p>Las métricas deportivas personales solo estarán disponibles con consentimiento y sincronización del atleta.</p></section>`);
 const settings=document.createElement('section');settings.className='connected-card connected-settings';settings.dataset.workspaceSection='settings';
 settings.innerHTML=`${trainer?`<nav class="business-settings-navigation" aria-label="Apartados de configuración"><button type="button" data-settings-section="profile" aria-current="${settingsSection==='profile'?'page':'false'}">Datos del profesional</button><button type="button" data-settings-section="plan" aria-current="${settingsSection==='plan'?'page':'false'}">Plan y suscripción</button></nav>`:''}<div data-settings-panel="profile"><span class="connected-tag">DATOS DEL ${trainer?'PROFESIONAL':'NEGOCIO'}</span><h2>Configuración de ${escapeHTML(org.name)}</h2><p>Solo propietarios o administradores pueden modificar los datos del negocio.</p><form data-connected="settings" class="settings-grid">
 <label class="connected-field">Nombre comercial<input name="name" maxlength="120" minlength="2" value="${escapeHTML(org.name)}" required ${!manager?'disabled':''}></label>
 <label class="connected-field">Email público<input name="publicEmail" type="email" maxlength="180" value="${escapeHTML(org.public_email||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field">Teléfono<input name="phone" maxlength="40" value="${escapeHTML(org.phone||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field">Sitio web<input name="website" type="url" maxlength="255" value="${escapeHTML(org.website||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field full">Dirección<input name="address" maxlength="300" value="${escapeHTML(org.address||'')}" ${!manager?'disabled':''}></label>
 <label class="connected-field full">Descripción<textarea name="description" rows="3" maxlength="2000" ${!manager?'disabled':''}>${escapeHTML(org.description||'')}</textarea></label>
 <label class="connected-field">Zona horaria<input name="timezone" maxlength="80" required value="${escapeHTML(org.timezone||'Europe/Madrid')}" ${!manager?'disabled':''}></label>
 <div class="full"><strong>Perfil:</strong> ${escapeHTML(kindLabel[kind]||kind)}</div>
 ${manager?'<button class="connected-primary" type="submit">Guardar datos</button>':''}</form></div>`;
 root.append(settings);
 attach('settings',`<div data-settings-panel="plan">${renderSubscriptions(org)}</div>`);
 // Centro y entrenador disponen de permisos diferentes; ocultar equipo al autónomo.
 if(trainer)root.querySelector('[data-workspace-section="team"]')?.remove();
 const trial=trialStatus();
 if(!trial.active&&activeTab!=='settings'){
  const notice=document.createElement('div');notice.className='connected-error';notice.innerHTML='<strong>Prueba finalizada.</strong> Para seguir administrando el negocio, elige un plan en Configuración. Los pagos todavía no están disponibles.';
  nav.insertAdjacentElement('afterend',notice);
 }
 root.querySelectorAll('[data-workspace-section]').forEach(el=>{el.style.display=el.dataset.workspaceSection===activeTab?'':'none';});
 if(trainer){root.querySelectorAll('[data-settings-panel]').forEach(el=>el.style.display=el.dataset.settingsPanel===settingsSection?'':'none');root.insertAdjacentHTML('beforeend',openBusinessDialog({org,manager,trainer,coaches:members}));}
}function render(){
 const common=`<header class="connected-header"><div class="brand"><span class="brand-symbol">R</span><span><strong>repera</strong><small>Business</small></span></div><a href="?demo=1" class="connected-demo">Abrir demostración local ↗</a></header>`;
 if(!user){
  const title={login:'Accede a tu negocio',register:'Crear cuenta profesional',recover:'Recuperar acceso',password:'Establecer nueva contraseña'}[view];
  const form=view==='login'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Entrar</button>`
   :view==='register'
   ?`${field('Correo electrónico','email','email')}${field('Contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<label class="connected-field">Tipo de actividad<select name="businessKind" required><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option><option value="sports_center">Centro deportivo</option></select></label>${field('Nombre comercial','businessName','text','minlength="2" maxlength="120"')}<p class="connected-hint">7 días de prueba gratuitos. No se pide tarjeta. Tras la prueba podrás elegir un plan; los pagos todavía no están habilitados.</p><button class="connected-primary" type="submit" ${busy?'disabled':''}>Registrarme y empezar prueba</button>`
   :view==='recover'
   ?`${field('Correo electrónico','email','email')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Enviar enlace</button>`
   :`${field('Nueva contraseña (8 caracteres mínimo)','password','password','minlength="8"')}<button class="connected-primary" type="submit" ${busy?'disabled':''}>Actualizar contraseña</button>`;
  app.innerHTML=`<div class="connected-page">${common}<main class="connected-auth"><div class="connected-card"><span class="connected-tag">PLATAFORMA PROFESIONAL</span><h1>${title}</h1><p class="connected-intro">Gestión real de organizaciones mediante Supabase. Tus entrenamientos personales permanecen en la app nativa.</p>${message()}<form data-connected="${view}">${form}</form><div class="connected-links">${view!=='login'?'<button type="button" data-view="login">Volver a iniciar sesión</button>':''}${view==='login'?'<button type="button" data-view="register">Crear cuenta</button><button type="button" data-view="recover">Olvidé mi contraseña</button>':''}</div></div></main></div>`;
  return;
 }
 const pendingInvites=invitations.filter(i=>!i.accepted_at&&!i.cancelled_at&&new Date(i.expires_at).getTime()>Date.now());
 const ownInvites=pendingInvites.filter(i=>i.email===(user.email||'').trim().toLowerCase());
 const own=new Map(memberships.filter(m=>m.user_id===user.id&&m.status==='active').map(m=>[m.organization_id,m.role]));
 app.innerHTML=`<div class="connected-page">${common}<main class="connected-workspace"><div class="connected-heading"><div><span class="connected-tag">SESIÓN AUTENTICADA · SUPABASE REPERA</span><h1>Mis organizaciones</h1><p>${escapeHTML(user.email||'Cuenta Repera')} · ${platformRole==='platform_admin'?'Administrador de plataforma · ':''}Solo se muestran negocios autorizados por la base de datos.</p></div><button class="connected-secondary" data-action="logout" ${busy?'disabled':''}>Cerrar sesión</button></div>${message()}${ownInvites.length?`<section class="connected-card" style="margin-bottom:22px"><h2>Invitaciones para ti</h2><p>Solo se vinculará tu cuenta con el profesional al aceptarla. No se compartirán tus datos privados de entrenamientos.</p>${ownInvites.map(i=>`<article class="connected-org"><div><strong>Organización ${escapeHTML(i.organization_id.slice(0,8))}</strong><small>Invitación para ${escapeHTML(roleLabel[i.invited_role]||i.invited_role)} · vence ${escapeHTML(i.expires_at.slice(0,10))}</small></div><button class="connected-primary" data-action="accept-invitation" data-id="${escapeHTML(i.id)}" ${busy?'disabled':''}>Aceptar</button></article>`).join('')}</section>`:''}<section data-workspace-section="overview" class="connected-grid"><div class="connected-card"><h2>Espacios de trabajo</h2>${organizations.length?organizations.map(o=>`<article class="connected-org"><div><strong>${escapeHTML(o.name)}</strong><small>${escapeHTML(kindLabel[o.kind]||o.kind)} · ${escapeHTML(roleLabel[own.get(o.id)]||'Miembro')}</small><code>${escapeHTML(o.slug)}</code></div>${['owner','admin'].includes(own.get(o.id))?`<form data-connected="rename" class="connected-inline"><input type="hidden" name="id" value="${escapeHTML(o.id)}"><label>Nombre<input name="name" value="${escapeHTML(o.name)}" maxlength="120" required></label><button class="connected-secondary" ${busy?'disabled':''}>Guardar</button></form>`:''}</article>`).join(''):'<p class="connected-empty">Todavía no perteneces a ninguna organización. Crea tu primera empresa para comenzar.</p>'}</div><div class="connected-card"><h2>Añadir organización</h2><p>Al crearla, Supabase te asigna el rol de propietario de forma segura.</p><form data-connected="create">${field('Nombre comercial','name','text','minlength="2" maxlength="120"')}${field('Identificador URL (minúsculas y guiones)','slug','text','minlength="3" maxlength="63" pattern="[a-z0-9][a-z0-9-]{2,62}"')}<label class="connected-field">Tipo<select name="kind"><option value="personal_trainer">Entrenador personal</option><option value="gym">Gimnasio</option><option value="sports_center">Centro deportivo</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear organización</button></form></div></section><section class="connected-card" data-workspace-section="clients" style="margin-top:22px"><h2>Clientes reales</h2><label class="connected-field">Organización<select id="connected-org-select"><option value="">Selecciona una organización</option>${organizations.map(o=>`<option value="${escapeHTML(o.id)}" ${selectedOrg===o.id?'selected':''}>${escapeHTML(o.name)}</option>`).join('')}</select></label>${selectedOrg?`<div style="margin-top:20px">${clients.length?clients.map(c=>`<article class="connected-org"><div><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email)} · ${escapeHTML(c.status)}</small></div></article>`).join(''):'<p>Sin clientes registrados en esta organización.</p>'}${['owner','admin'].includes(own.get(selectedOrg))?`<form data-connected="client">${field('Nombre del cliente','name','text','minlength="2" maxlength="120"')}${field('Correo electrónico','email','email')}<button class="connected-primary">Añadir cliente potencial</button></form>`:''}</div>`:''}</section>${selectedOrg&&["owner","admin"].includes(own.get(selectedOrg))?`<section class="connected-card" data-workspace-section="team" style="margin-top:22px"><h2>Invitar a mi organización</h2><p>La persona debe registrarse con el mismo correo verificado. Podrá aceptar la invitación al iniciar sesión. Aún no se envían correos automáticos.</p><form data-connected="invite">${field('Correo del invitado','email','email')}<label class="connected-field">Perfil<select name="role"><option value="athlete">Deportista</option><option value="coach">Entrenador</option><option value="reception">Recepción</option><option value="admin">Administrador</option></select></label><button class="connected-primary" ${busy?'disabled':''}>Crear invitación</button></form>${pendingInvites.filter(i=>i.organization_id===selectedOrg).length?`<p>Invitaciones pendientes: ${pendingInvites.filter(i=>i.organization_id===selectedOrg).length}</p>`:''}</section>`:''}${renderProfessionalPlanning({orgId:selectedOrg,role:own.get(selectedOrg),sessions:professionalSessions,templates,clients,memberships,busy,escapeHTML,templateId:selectedTemplateId,sessionId:editingSessionId,clientId:planningClientId})}<div data-workspace-section="services">${renderServicesPanel({selectedOrg,role:own.get(selectedOrg),occurrences,passes,bookings,clients,memberships,busy,escapeHTML})}</div><section class="connected-next"><h2>Próximos módulos</h2><p>Asignación operativa de entrenadores, planes publicados, compra de bonos y reservas desde las apps móviles aún no están conectados. No se muestran datos ficticios en este espacio autenticado.</p><a href="?demo=1">Explorar funciones en la demostración (sin datos reales)</a></section></main></div>`;
 enhanceWorkspace(own);
}
const PENDING_REGISTRATION_KEY='repera-business-pending-professional-v1';
const slugFromName=name=>String(name||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'').slice(0,60);
async function finalizePendingRegistration(){
 const raw=sessionStorage.getItem(PENDING_REGISTRATION_KEY);if(!raw||!user)return;
 if(organizations.length){sessionStorage.removeItem(PENDING_REGISTRATION_KEY);return;}
 const pending=JSON.parse(raw);
 if(pending?.email!==String(user.email||'').toLowerCase())return;
 if(!pending||!['personal_trainer','gym','sports_center'].includes(pending.kind)||typeof pending.name!=='string')return;
 const slug=slugFromName(pending.name).slice(0,53)+'-'+crypto.randomUUID().slice(0,6);
 if(slug.length<3)throw Error('El nombre comercial debe contener tres caracteres para generar el identificador.');
 await auth.createOrganization({name:pending.name,slug,kind:pending.kind,userId:user.id});
 sessionStorage.removeItem(PENDING_REGISTRATION_KEY);await reload();
}
async function loadSelectedOrg(){
 let clientAvatars=[];
 if(!selectedOrg){clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];trialRows=[];classDetails=[];groups=[];groupMembers=[];notices=[];return;}
 [clients,occurrences,passes,bookings,professionalSessions,templates,trialRows,classDetails,groups,groupMembers,notices,clientAvatars]=await Promise.all([
 auth.clients(selectedOrg),auth.serviceOccurrences(selectedOrg),auth.servicePasses(selectedOrg),
 auth.serviceBookings(selectedOrg),auth.professionalSessions(selectedOrg),auth.workoutTemplates(selectedOrg),
 auth.organizationTrial(selectedOrg),auth.classDetails(selectedOrg),auth.groupList(selectedOrg),auth.groupMembers(selectedOrg),auth.clientNotifications(selectedOrg),auth.clientAvatars(selectedOrg).catch(()=>[])]);
 const avatars=new Map(clientAvatars.map(a=>[a.client_id,a.avatar_url]));
 clients=clients.map(c=>({...c,avatar_url:avatars.get(c.id)||c.avatar_url}));
}
async function reload(){
 const [orgs,members,invites,profile]=await Promise.all([auth.organizations(),auth.memberships(),auth.invitations(),auth.myProfile()]);platformRole=profile?.role||null;
 organizations=orgs||[];memberships=members||[];invitations=invites||[];
 if(!organizations.some(o=>o.id===selectedOrg))selectedOrg=organizations[0]?.id||null;
 platformOrgs=platformRole==='platform_admin'?await auth.platformOverview():[];
 await loadSelectedOrg();
}
app.addEventListener('click',async event=>{
 if(handleEditorClick(event))return;
 const tab=event.target.closest('[data-workspace]');if(tab){activeTab=tab.dataset.workspace;businessDialog='';setWorkspaceRoute();render();return;}
 const mode=event.target.closest('[data-view]');if(mode){view=mode.dataset.view;error=notice='';render();return;}
 const actionable=event.target.closest('[data-action]');const action=actionable?.dataset.action;
 const trainer=organizations.find(o=>o.id===selectedOrg)?.kind==='personal_trainer';
 const setting=event.target.closest('[data-settings-section]');if(setting){settingsSection=setting.dataset.settingsSection==='plan'?'plan':'profile';render();return;}
 if(action==='close-business-dialog'||action==='back-classes'&&trainer||action==='back-groups'&&trainer){businessDialog='';selectedClassId=null;selectedGroupId=null;render();return;}
 if(action==='new-date-appointment'){dialogDay=actionable.dataset.day;businessDialog='new-appointment';render();return;}
 if(action==='calendar-today'){calendarMonth='';render();return;}
 if(action==='add-planning'){selectedClientId=actionable.dataset.id||selectedClientId;businessDialog='bulk';setWorkspaceRoute();render();return;}
 if(action==='delete-session'&&!busy){if(!confirm('¿Eliminar este entrenamiento del calendario del deportista? Esta acción no borra su historial deportivo.'))return;busy=true;render();try{await auth.cancelProfessionalSession(actionable.dataset.id);await loadSelectedOrg();notice='Entrenamiento retirado de la planificación.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='end-client'&&!busy){const client=clients.find(c=>c.id===actionable.dataset.id);if(!client)return;if(!confirm('Confirma que el contrato de este cliente ya ha finalizado. Se dará de baja su relación con este profesional, sin cancelar su cuenta de Repera ni su suscripción independiente.'))return;busy=true;render();try{await auth.updateClientProfile({orgId:selectedOrg,id:client.id,name:client.name,email:client.email,phone:client.phone,notes:client.notes,avatar:client.avatar_url,status:'cancelled'});await loadSelectedOrg();notice='Relación profesional finalizada. La cuenta personal del deportista se conserva.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='detail-client'){selectedClientId=actionable.dataset.id;planningClientId=selectedClientId;sharedHistory=[];activeTab='clients';businessDialog='';setWorkspaceRoute();render();try{sharedHistory=await auth.sharedClientHistory({orgId:selectedOrg,clientId:selectedClientId});}catch(e){error='El historial privado no está disponible para este profesional.';}render();return;}
 if(action==='back-clients'){sharedHistory=[];selectedClientId=null;planningClientId=null;editingSessionId=null;selectedTemplateId=null;activeTab='clients';setWorkspaceRoute();render();return;}
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
 if(action==='publish-class-plan'){classEditorId=actionable.dataset.id;selectedClassId=actionable.dataset.id;activeTab='services';render();return;}
 if(action==='plan-client'){planningClientId=actionable.dataset.id;selectedClientId=planningClientId;activeTab=trainer?'clients':'planning';selectedTemplateId=null;editingSessionId=null;setWorkspaceRoute();render();return;}
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
 if(action==='use-template'){selectedTemplateId=actionable.dataset.id;editingSessionId=null;activeTab=trainer?'clients':'planning';setWorkspaceRoute();render();return;}
 if(action==='edit-session'){const s=professionalSessions.find(s=>s.id===actionable.dataset.id);if(trainer&&s){selectedClientId=s.client_id;planningClientId=s.client_id;}editingSessionId=actionable.dataset.id;selectedTemplateId=null;activeTab=trainer?'clients':'planning';setWorkspaceRoute();render();return;}
 if(action==='accept-invitation'&&!busy){busy=true;error=notice='';render();try{await auth.acceptInvitation(actionable.dataset.id);await reload();notice='Invitación aceptada. Tu relación con el centro ya consta en Supabase.';}catch(e){error=e.message;}finally{busy=false;render();}return;}
 if(action==='logout'){busy=true;render();try{await auth.signOut();user=null;organizations=[];memberships=[];invitations=[];view='login';notice='Sesión cerrada';}catch(e){user=null;organizations=[];memberships=[];view='login';notice='Sesión local cerrada. No se pudo confirmar el cierre remoto.';}finally{busy=false;render();}}
});
app.addEventListener('input',event=>{handleEditorSearch(event);});
app.addEventListener('change',async event=>{if(!['connected-org-select','workspace-org-select'].includes(event.target.id))return;selectedOrg=event.target.value||null;businessDialog='';selectedClientId=null;selectedClassId=null;selectedGroupId=null;planningClientId=null;sharedHistory=[];activeTab='overview';selectedTemplateId=null;editingSessionId=null;error='';clients=[];occurrences=[];passes=[];bookings=[];professionalSessions=[];templates=[];
 if(selectedOrg){try{await loadSelectedOrg();}catch(e){error=e.message;}}
 setWorkspaceRoute();render();});
app.addEventListener('submit',async event=>{
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
  if(action==='bulk-plan'){
   const ids=[...new Set(data.getAll('clients').map(String))];
   if(!ids.length||ids.some(id=>!clients.some(c=>c.id===id&&c.status==='active'&&c.user_id)))throw Error('Selecciona al menos un deportista activo y vinculado.');
   const from=String(data.get('from')||''),until=String(data.get('until')||'');
   if(!/^\d{4}-\d{2}-\d{2}$/.test(from)||!/^\d{4}-\d{2}-\d{2}$/.test(until))throw Error('Selecciona las fechas.');
   const start=Date.parse(from+'T12:00:00Z'),end=Date.parse(until+'T12:00:00Z'),days=Math.round((end-start)/86400000)+1;
   if(!Number.isFinite(days)||days<1||days>60||days*ids.length>60)throw Error('La planificación debe contener entre 1 y 60 asignaciones en total.');
   const template=templates.find(t=>t.id===data.get('template')),templateId=data.get('template');
   if(templateId&&!template)throw Error('La plantilla seleccionada ya no existe.');
   const title=String(data.get('title')||'').trim(),instructions=String(data.get('instructions')||'');
   if(title.length<2||title.length>120||instructions.length>10000)throw Error('Revisa el título y las indicaciones.');
   let created=0;const failures=[];
   for(let d=0;d<days;d++){const date=new Date(start+d*86400000).toISOString().slice(0,10);
    for(const id of ids){try{await auth.publishProfessionalSession({orgId:selectedOrg,clientId:id,date,title,instructions,prescription:template?.prescription||emptyPrescription()});created++;}catch(e){failures.push(date+': '+e.message);}}
   }
   await loadSelectedOrg();
   if(failures.length){error='Asignaciones guardadas: '+created+'. Fallaron '+failures.length+': '+failures.slice(0,3).join('; ');notice='Consulta las fichas antes de repetir la operación para evitar duplicados.';}
   else{businessDialog='';notice=created+' entrenamientos programados correctamente.';}
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
  if(action==='rename'){await auth.renameOrganization(data.get('id'),data.get('name'));await reload();notice='Nombre actualizado.';}
  if(action==='settings'){await auth.updateOrganization({orgId:selectedOrg,name:data.get('name'),publicEmail:data.get('publicEmail'),phone:data.get('phone'),website:data.get('website'),address:data.get('address'),description:data.get('description'),timezone:data.get('timezone')});await reload();notice='Datos del negocio actualizados.';}
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
