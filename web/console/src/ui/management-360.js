import {renderSharedAthleteSessions,renderAthleteActivity} from './athlete-activity.js';
import {renderAthleteInsights,renderAthleteGuidanceLine} from './athlete-insights.js';
import {editorMarkup,emptyPrescription,visualPrescription} from './workout-editor.js';
import {renderAssignOfflinePassForm,passProvenanceLabel} from './gym-pass-panel.js';
import {renderClientChatThread,renderBroadcastPanel} from './business-chat.js';
import {renderTrainerAgenda,collectDayEvents,todayISO} from './trainer-agenda.js';
// Vistas 360 de Repera Business: nunca inventan estadísticas del atleta sin consentimiento.
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const dateTime=x=>x?new Date(x).toLocaleString('es-ES',{dateStyle:'medium',timeStyle:'short'}):'Sin fecha';
const day=x=>x?new Date(x).toLocaleDateString('es-ES',{dateStyle:'short'}):'—';
const short=x=>x?new Date(x).toLocaleDateString('sv-SE'):'';
const initials=s=>String(s||'').trim().split(/\s+/).slice(0,2).map(t=>t[0]||'').join('').toUpperCase();
const button=(label,action,id='',more='')=>`<button type="button" class="connected-secondary" data-action="${action}" data-id="${esc(id)}" ${more}>${label}</button>`;
const primary=(label,action,id='',more='')=>`<button type="button" class="connected-primary" data-action="${action}" data-id="${esc(id)}" ${more}>${label}</button>`;
const input=(label,name,value='',type='text',attrs='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" value="${esc(value)}" ${attrs}></label>`;
const select=(label,name,rows,selected='')=>`<label class="connected-field">${label}<select name="${name}">${rows.map(([value,title])=>`<option value="${esc(value)}" ${String(value)===String(selected)?'selected':''}>${esc(title)}</option>`).join('')}</select></label>`;
const note=t=>`<p class="connected-hint">${esc(t)}</p>`;
const show=(html)=>`<section class="connected-card business-360">${html}</section>`;
const statusBadge=(label,tone='neutral')=>`<span class="business-status-badge tone-${tone}"><span class="business-status-dot" aria-hidden="true"></span>${esc(label)}</span>`;
const bookingStatusLabel={booked:['Reservado','info'],attended:['Asistió','ok'],no_show:['No presentado','warn'],cancelled:['Cancelado','muted']};

function enrollmentInbox(manager,waiting){
 if(!manager)return show('<h2>Quieren entrenar contigo</h2>'+note('No tienes permiso para gestionar solicitudes.'));
 return show(`<div class="business-panel-head">
 <div><h2>Solicitudes</h2>
 <p>Piden entrenar contigo desde la app. Aceptar vincula; no da bono ni Pro.</p></div>
 <div class="business-inbox-tools"><span class="business-inbox-count">${waiting.length}</span>
 <button type="button" data-action="refresh-enrollments" class="connected-secondary" aria-label="Actualizar">Actualizar</button></div></div>
 ${waiting.length?`<div class="business-inbox-list">${waiting.map(r=>`
 <article class="business-enrollment-row">
 <div class="business-enrollment-avatar">${/^https:\/\//.test(r.avatar_url||'')?`<img src="${esc(r.avatar_url)}" alt="" loading="lazy">`:esc(initials(r.name))}</div>
 <div class="business-enrollment-text"><strong>${esc(r.name||'Atleta')}</strong><small>${esc(r.email||'—')} · ${r.pass_kind==='appointment'?'Entrenamiento personal':'Clases'}</small>
 ${r.note?`<p>${esc(r.note)}</p>`:''}</div>
 <div class="business-enrollment-actions">
  <button type="button" class="connected-primary" data-action="approve-enrollment" data-id="${esc(r.id)}">Aceptar</button>
  <button type="button" class="connected-secondary" data-action="reject-enrollment" data-id="${esc(r.id)}">Rechazar</button>
 </div></article>`).join('')}</div>`:
 '<div class="business-inbox-empty">No hay solicitudes. Cuando alguien pida vincularse desde la app, aparecerá aquí.</div>'}`);
}

function renderTrainerOverview({inbox,clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView='month',agendaDay='',gymAssignments=[]}){
 return renderTrainerAgenda({
  clients,occurrences,bookings,sessions,gymAssignments,calendarMonth,agendaView,agendaDay,manager,
  inboxHtml:compactEnrollmentInbox(inbox),
 });
}
function compactEnrollmentInbox(inboxHtml){
 // El inbox ya es HTML de enrollmentInbox; lo envolvemos más denso bajo la agenda.
 if(!inboxHtml||!String(inboxHtml).includes('Solicitudes'))return inboxHtml||'';
 return `<div class="pt-inbox-wrap">${inboxHtml}</div>`;
}

function renderGymReceptionHome({clients,occurrences,bookings,requests,manager,passes=[]}){
 const today=new Date().toLocaleDateString('sv-SE');
 const todayClasses=occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at).toLocaleDateString('sv-SE')===today)
  .sort((a,b)=>a.starts_at.localeCompare(b.starts_at));
 const waiting=requests.filter(r=>r.status==='pending');
 const openBookings=bookings.filter(b=>b.status==='booked');
 const soon=occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at)>new Date()).sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).slice(0,6);
 const ops=`<section class="business-reception" aria-label="Recepción">
  <div class="business-panel-head"><div><span class="connected-eyebrow">Operaciones de hoy</span><h2>Recepción</h2>
  <p>Busca un socio y registra asistencia o asigna bono sin salir del contexto.</p></div>
  ${manager?primary('Invitar socio','go-invite-client'):''}</div>
  <label class="connected-field business-reception-search">Buscar socio
   <input type="search" data-reception-filter placeholder="Nombre o correo" autocomplete="off" aria-controls="reception-results">
  </label>
  <div id="reception-results" class="business-reception-results" role="list">
   ${clients.filter(c=>!c.account_deleted_at).slice(0,12).map(c=>{
    const pass=passes.filter(p=>p.client_id===c.id&&p.status==='active').sort((a,b)=>b.remaining_credits-a.remaining_credits)[0];
    const dayBooking=openBookings.find(b=>b.client_id===c.id&&occurrences.some(o=>o.id===b.occurrence_id&&new Date(o.starts_at).toLocaleDateString('sv-SE')===today));
    return `<article class="business-reception-row" role="listitem" data-reception-name="${esc((c.name+' '+(c.email||'')).toLowerCase())}">
     <div class="business-client-person"><span class="business-avatar">${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?`<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}</span>
     <div><strong>${esc(c.name)}</strong><small>${esc(c.email||'—')} · ${pass?`${pass.remaining_credits} créditos`:'Sin bono activo'}${dayBooking?' · Reserva hoy':''}</small></div></div>
     <div class="business-reception-actions">
      ${manager&&dayBooking?button('Registrar asistencia','mark-booking-attended',dayBooking.id):''}
      ${manager?button('Asignar bono','detail-client-passes',c.id):''}
      ${button('Ver ficha','detail-client',c.id)}
     </div></article>`;
   }).join('')||'<p class="business-empty">Todavía no hay socios. Invita al primero.</p>'}
  </div>
 </section>`;
 const todayPanel=show(`<div class="business-panel-head"><div><h2>Clases de hoy</h2><p>Aforo ocupado / capacidad. Abre el detalle para asistencia.</p></div>${button('Agenda completa','open-class-calendar')}</div>
  <div class="business-cards">${todayClasses.length?todayClasses.map(o=>{
   const n=bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended'].includes(b.status)).length;
   return `<button type="button" class="business-class-tile" data-action="detail-occurrence" data-id="${esc(o.id)}">
    <span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong>
    <small>${o.kind==='appointment'?'Cita':'Clase'} · ${n}/${o.capacity} plazas ${n>=o.capacity?statusBadge('Completa','warn'):statusBadge('Plazas','ok')}</small>
    <span class="business-tile-arrow">Gestionar →</span></button>`;
  }).join(''):'<p class="business-empty">No hay clases hoy. '+ (manager?'Crea una en Agenda y clases.':'') +'</p>'}</div>`);
 return `${ops}${todayPanel}${enrollmentInbox(manager,waiting)}${show(`<div class="business-panel-head"><div><h2>Próximas clases</h2></div></div>
  <div class="business-cards">${soon.length?soon.map(o=>`<button type="button" class="business-class-tile" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong><small>${bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended'].includes(b.status)).length}/${o.capacity} plazas</small></button>`).join(''):'<p class="business-empty">Sin próximas clases programadas.</p>'}</div>`)}`;
}

export function renderBusinessHome({org,clients=[],occurrences=[],bookings=[],sessions=[],templates=[],requests=[],manager=false,calendarMonth='',passes=[],groups=[],busy=false,escapeHTML=esc,agendaView='month',agendaDay='',gymAssignments=[]}){
 const waiting=requests.filter(r=>r.status==='pending');
 const inbox=enrollmentInbox(manager,waiting);
 const broadcast=manager?renderBroadcastPanel({clients,occurrences,groups,manager,busy}):'';
 if(org?.kind==='personal_trainer')return renderTrainerOverview({inbox,clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView,agendaDay,gymAssignments})+broadcast;
 return renderGymReceptionHome({clients,occurrences,bookings,requests,manager,passes})+broadcast;
}
const localDay=x=>{
 if(!x)return '';
 const d=new Date(x);return Number.isNaN(d.valueOf())?'':new Intl.DateTimeFormat('sv-SE',{timeZone:'Europe/Madrid',year:'numeric',month:'2-digit',day:'2-digit'}).format(d);
};
function athleteLoggedRows(rows){
 return rows.map(r=>({id:r.id,title:r.title,started_at:r.started_at,finished_at:r.finished_at,
  exercises:Array.isArray(r.result?.exercises)?r.result.exercises:[],
  wod_results:Array.isArray(r.result?.wodResults)?r.result.wodResults:[]}));
}
function trainerDays({sharedHistory,sessions,attendance}){
 const counts=new Map();
 const push=d=>{if(d)counts.set(d,(counts.get(d)||0)+1);};
 sharedHistory.forEach(r=>push(localDay(r.started_at||r.finished_at)));
 sessions.forEach(s=>push(s.scheduled_date));
 attendance.forEach(a=>push(localDay(a.performed_at)));
 return [...counts.entries()].map(([day,count])=>({day,count}));
}

export function renderClient360({clients=[],selected=null,passes=[],offers=[],bookings=[],occurrences=[],sessions=[],notices=[],chatMessages=[],sharedHistory=[],attendance=[],trainerActivityMonth='',trainerActivityDay='',manager=false,role='',trainer=false,busy=false,escapeHTML=esc,clientSection='training',clientQuery='',gymAssignments=[]}){
 if(!selected){
  const q=String(clientQuery||'').trim().toLowerCase();
  const filtered=clients.filter(c=>{
   if(!q)return true;
   const hay=((c.name||'')+' '+(c.email||'')).toLowerCase();
   return hay.includes(q);
  });
  return show(`<div class="business-panel-head pt-clients-head"><div>
 <h2>Clientes</h2></div>
 ${manager?primary('Invitar cliente','open-invite-modal'):''}</div>
 <label class="connected-field pt-client-search">Buscar
  <input type="search" data-client-filter value="${esc(clientQuery||'')}" placeholder="Nombre o correo" autocomplete="off">
 </label>
 <div class="business-client-table-wrap"><table class="business-client-table"><thead><tr>
 <th>Cliente</th><th>Correo</th><th>Vinculación</th><th>Bono</th><th>Estado</th></tr></thead><tbody>
 ${filtered.map(c=>{
  const p=passes.filter(x=>x.client_id===c.id&&x.status==='active').sort((a,b)=>b.remaining_credits-a.remaining_credits)[0];
  return `<tr role="link" tabindex="0" data-action="detail-client" data-id="${esc(c.id)}">
 <td><div class="business-client-person"><span class="business-avatar">${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?
 `<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}</span>
 <strong>${esc(c.name)}</strong></div></td><td>${esc(c.email||'—')}</td>
 <td>${c.account_deleted_at?'Histórico':c.user_id?'Vinculado':'Pendiente'}</td>
 <td>${p?(p.remaining_credits>=9000?'Ilimitado':`${p.remaining_credits}/${p.total_credits}`):'—'}</td>
 <td>${c.account_deleted_at?'Solo lectura':statusBadge(c.status,c.status==='active'?'ok':c.status==='cancelled'?'muted':'info')}</td></tr>`;}).join('')||
 '<tr><td colspan="5"><p class="business-empty">Todavía no hay clientes. Invita al primero.</p></td></tr>'}
 </tbody></table></div>`);
 }
 const c=clients.find(x=>x.id===selected);if(!c)return show('La persona seleccionada no está autorizada para este centro.');
  const archived=Boolean(c.account_deleted_at);
 const ownPasses=passes.filter(p=>p.client_id===c.id),
 activePass=ownPasses.filter(p=>p.status==='active').sort((a,b)=>b.remaining_credits-a.remaining_credits)[0],
 ownBookings=bookings.filter(b=>b.client_id===c.id),
 ownSessions=sessions.filter(s=>s.client_id===c.id&&(archived||s.status==='scheduled'));
 const nextBooking=ownBookings.filter(b=>['booked','attended'].includes(b.status)).map(b=>{
  const o=occurrences.find(o=>o.id===b.occurrence_id);return o?{b,o}:null;
 }).filter(Boolean).filter(x=>new Date(x.o.starts_at)>=new Date()).sort((a,b)=>a.o.starts_at.localeCompare(b.o.starts_at))[0];
 const logged=athleteLoggedRows(sharedHistory);
 const ownAttendance=attendance.filter(a=>a.client_id===c.id);
 // Agenda fusionada en Entrenamientos para PT; Mensajes y Datos aparte.
 const tabDefs=[['training','Entrenamientos'],['passes','Bonos'],['chat','Mensajes'],...(trainer?[]:[['bookings','Reservas']]),['data','Datos']];
 const section=tabDefs.some(([id])=>id===clientSection)?clientSection:(clientSection==='agenda'?'training':clientSection);
 const safeSection=tabDefs.some(([id])=>id===section)?section:'training';
 const tabs=`<nav class="business-client-tabs" aria-label="Ficha de cliente">
 ${tabDefs.map(([id,name])=>
 `<button type="button" data-action="client-section" data-section="${id}" class="${safeSection===id?'active':''}"
 aria-current="${safeSection===id?'page':'false'}">${name}</button>`).join('')}</nav>`;
 const linkLabel=archived?'Cuenta eliminada':c.user_id?'Vinculado':'Invitación pendiente';
 const head=`<div class="pt-client-topbar">
  ${button('← Clientes','back-clients')}
  <div class="pt-client-top-actions">
   ${!archived&&manager?primary('Añadir entreno',trainer?'open-quick-workout':'plan-client',c.id):''}
   ${!archived&&manager&&!c.user_id?button('Preparar invitación','invite-client',c.id):''}
   ${!archived&&manager&&trainer&&c.status!=='cancelled'?button('Finalizar','end-client',c.id):''}
  </div>
 </div>
 <div class="business-profile-header pt-profile-header"><span class="business-avatar large">
 ${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?`<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}
 </span><div><h2>${esc(c.name)}</h2>
 <p>${esc(c.email||'—')} · ${statusBadge(linkLabel,archived?'muted':c.user_id?'ok':'info')}
 ${activePass?` · ${activePass.remaining_credits>=9000?'Ilimitado':`${activePass.remaining_credits}/${activePass.total_credits}`} · ${passProvenanceLabel(activePass)}`:''}
 ${nextBooking?` · Próximo: ${esc(nextBooking.o.title)} ${dateTime(nextBooking.o.starts_at)}`:''}</p>
 ${trainer?renderAthleteGuidanceLine(logged,sharedHistory.length):''}
 </div></div>`;
 let body='';
 if(safeSection==='training'){
  if(trainer){
   const currentMonth=/^\d{4}-\d{2}$/.test(trainerActivityMonth)?trainerActivityMonth:new Date().toLocaleDateString('sv-SE').slice(0,7);
   const currentDay=/^\d{4}-\d{2}-\d{2}$/.test(trainerActivityDay)?trainerActivityDay:todayISO();
   const dayEvents=collectDayEvents({
    day:currentDay,clients:[c],
    occurrences:occurrences.filter(o=>ownBookings.some(b=>b.occurrence_id===o.id)||o.kind==='appointment'),
    bookings:ownBookings,sessions:ownSessions,gymAssignments:[],
   });
   const daily=logged.filter(w=>localDay(w.started_at||w.finished_at)===currentDay);
   const planned=ownSessions.filter(s=>s.scheduled_date===currentDay);
   body=`<div class="pt-client-agenda">
    <div class="business-panel-head"><div><h3>Agenda de ${esc(c.name)}</h3>
     <p>Citas y entrenos de este cliente.</p></div>
     ${manager&&!archived?button('Añadir entreno','open-quick-workout',c.id):''}</div>
    <div class="pa-athlete-training-grid trainer-client-grid">
    ${renderAthleteActivity({month:currentMonth,selectedDay:currentDay,
      days:trainerDays({sharedHistory,sessions:ownSessions,attendance:ownAttendance}),
      workouts:daily,plannedSessions:planned,athleteId:c.id,actionNamespace:'trainer',
      canPlan:manager&&!archived,emptyText:'Elige un día para ver o programar.'})}</div>
    <div class="pt-day-events">${dayEvents.length?dayEvents.map(ev=>`<article class="pt-event-card">
      <button type="button" class="pt-event-main" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}">
       <strong>${esc(ev.title)}</strong><small>${esc(ev.subtitle)}</small></button>
      ${ev.kind==='entreno'&&manager?button('Editar','edit-session',ev.id):''}
      ${ev.kind==='cita'&&manager&&ownBookings.find(b=>b.occurrence_id===ev.id&&b.status==='booked')?
        button('Cancelar reserva','remove-booking',ownBookings.find(b=>b.occurrence_id===ev.id&&b.status==='booked').id):''}
     </article>`).join(''):'<p class="business-empty">Nada este día.</p>'}</div>
    ${ownAttendance.length?`<section class="business-detail-panel trainer-attendance-history"><h3>Sesiones presenciales</h3>
      <div class="business-attendance-rows">${ownAttendance.slice(0,12).map(a=>`<div class="business-line"><strong>${dateTime(a.performed_at)}</strong><small>${esc(a.note||'Sesión con el entrenador')}</small></div>`).join('')}</div></section>`:''}
    ${renderAthleteInsights(logged,sharedHistory.length,{showGuidance:false})}
   </div>`;
  }else{
   body=`<div class="business-360-grid">
   <div class="business-detail-panel"><div class="business-panel-head"><h3>Entrenamientos</h3>
   ${archived?'':primary('Añadir entreno','plan-client',c.id)}</div>
   ${ownSessions.length?ownSessions.map(s=>`<article class="business-line"><strong>${esc(s.title)}</strong>
   <small>${day(s.scheduled_date)} · ${(s.prescription?.blocks||[]).length} bloques</small>
   ${archived?'':button('Editar','edit-session',s.id)}${!archived&&manager?button('Eliminar','delete-session',s.id):''}</article>`).join(''):
   '<p class="business-empty">Aún no hay entrenamientos. Añade el primero.</p>'}</div>
   <div class="business-detail-panel"><h3>Actividad compartida</h3>
   ${sharedHistory.length?`<p>${sharedHistory.length} sesiones compartidas.</p>
   ${renderSharedAthleteSessions(sharedHistory)}`:
   note('Solo actividades autorizadas por el atleta.')}</div></div>`;
  }
 }
 if(safeSection==='chat'){
  body=`<div class="pt-chat-shell business-detail-panel">
  ${renderClientChatThread({messages:chatMessages,clientId:c.id,busy})}</div>`;
 }
 if(safeSection==='passes'){
  body=`<div class="business-360-grid">
  <div class="business-detail-panel"><h3>Saldo y bonos</h3>
  ${ownPasses.length?ownPasses.map(p=>`<article class="business-line">
   <strong>${p.kind==='class'?'Clases':'Citas'}</strong>
   <small>${p.remaining_credits}/${p.total_credits} disponibles · ${esc(passProvenanceLabel(p))} · hasta ${day(p.valid_until)}</small>
   ${manager&&!archived&&p.issuance_type==='complimentary'?`<form data-connected="manage-pass" class="business-inline-form">
    <input type="hidden" name="pass" value="${esc(p.id)}">
    <input type="hidden" name="op" value="add_credits">
    ${input('Añadir créditos (cortesía)','amount','1','number','min="1" max="100" required')}
    <button type="submit" class="connected-secondary">Añadir</button></form>`:''}
  </article>`).join(''):'<p class="business-empty">Sin bonos. Asigna uno tras confirmar el cobro fuera de Repera.</p>'}
  </div>
  <div class="business-detail-panel"><h3>Asignar bono</h3>
  ${archived?note('Cuenta archivada: no se pueden asignar bonos.'):
   renderAssignOfflinePassForm({clients:[c],offers,clientId:c.id,manager,busy})}
  <p class="connected-hint">Procedencia: Confirmado por el centro (manual). No es verificación bancaria.</p>
  </div></div>`;
 }
 if(safeSection==='data'){
  body=`<div class="pt-data-card business-detail-panel">
 <div class="pt-data-grid">
  <div><span class="pt-data-label">Nombre</span><strong>${esc(c.name)}</strong></div>
  <div><span class="pt-data-label">Correo</span><strong>${esc(c.email||'—')}</strong></div>
  <div><span class="pt-data-label">Cuenta</span><strong>${archived?'Eliminada':c.user_id?'Vinculada':'Pendiente'}</strong></div>
  <div><span class="pt-data-label">Estado</span><strong>${archived?'Histórico':esc(c.status)}</strong></div>
 </div>
 ${archived?'<p class="connected-hint">Registro histórico, solo lectura.</p>':''}
 ${manager&&!archived?`<form data-connected="client-profile" class="business-form pt-data-form">
 ${input('Nombre','name',c.name,'text','required minlength="2" maxlength="120"')}
 ${input('Correo','email',c.email,'email','required')}
 ${select('Estado','status',['lead','trial','active','paused',...(trainer&&c.status!=='cancelled'?[]:['cancelled'])].map(v=>[v,v]),c.status)}
 <input type="hidden" name="client" value="${esc(c.id)}">
 <button type="submit" class="connected-primary">Guardar</button></form>`:''}</div>`;
 }
 if(safeSection==='bookings'){
  body=`<div class="business-360-grid">
 <div class="business-detail-panel"><div class="business-panel-head"><h3>${trainer?'Agenda y citas':'Reservas'}</h3>
 ${!archived&&manager&&!trainer?button('Inscribir en clase','find-class-for-client',c.id):''}
 ${!archived&&manager&&trainer?button('Registrar sesión','trainer-session',c.id):''}</div>
 ${ownBookings.length?ownBookings.map(b=>{const o=occurrences.find(o=>o.id===b.occurrence_id);
 const st=bookingStatusLabel[b.status]||[b.status,'neutral'];
 return `<article class="business-line"><strong>${esc(o?.title||'Clase')}</strong>
 <small>${dateTime(o?.starts_at)} · ${statusBadge(st[0],st[1])}</small>
 ${manager&&b.status==='booked'?`<span class="business-line-actions">${button('Asistió','mark-booking-attended',b.id)}${button('No presentado','mark-booking-noshow',b.id)}</span>`:''}
 </article>`;}).join(''):'<p class="business-empty">Sin reservas.</p>'}</div>
 <div class="business-detail-panel"><h3>Entrenamientos fechados</h3>
 ${ownSessions.length?ownSessions.map(t=>`<article class="business-line"><strong>${esc(t.title)}</strong>
 <small>${day(t.scheduled_date)} · ${esc(t.status)}</small></article>`).join(''):
 '<p class="business-empty">Sin sesiones profesionales.</p>'}</div></div>`;
 }
 return show(head+tabs+body);
}
export function renderClasses360({occurrences=[],clients=[],bookings=[],passes=[],details=[],groups=[],groupMembers=[],selectedGroup=null,coaches=[],selected=null,classEditor=false,listMode='calendar',calendarMonth='',activeClient=null,manager=false,escapeHTML=esc}){
 const index=new Map(details.map(d=>[d.occurrence_id,d]));
 if(selectedGroup){
  const g=groups.find(g=>g.id===selectedGroup);
  if(!g)return show('<p>Grupo no encontrado.</p>');
  const members=new Set(groupMembers.filter(x=>x.group_id===selectedGroup).map(x=>x.client_id));
  return show(`${button('← Volver a clases y grupos','back-groups')}<div class="business-profile-header"><span class="business-avatar large">${esc(initials(g.name))}</span><div><h2>${esc(g.name)}</h2><p>${members.size} deportistas en este grupo</p></div></div>
  ${manager?`<form data-connected="edit-group" class="business-form"><input type="hidden" name="group" value="${esc(g.id)}">
   ${input('Nombre del grupo','name',g.name,'text','required minlength="2" maxlength="100"')}
   ${input('Descripción','description',g.description||'','text','maxlength="500"')}
   <h3>Participantes</h3><div class="business-group-members">${clients.map(c=>`<label><input type="checkbox" name="members" value="${esc(c.id)}" ${members.has(c.id)?'checked':''}><span class="business-avatar">${esc(initials(c.name))}</span><strong>${esc(c.name)}</strong></label>`).join('')}</div>
   <button class="connected-primary">Guardar grupo y miembros</button></form>`:
   clients.filter(c=>members.has(c.id)).map(c=>`<div class="business-roster"><span class="business-avatar">${esc(initials(c.name))}</span><strong>${esc(c.name)}</strong></div>`).join('')}
  `);
 }

 if(selected){
  const o=occurrences.find(o=>o.id===selected);if(!o)return show('<p>No se encuentra la clase.</p>');
  const roster=bookings.filter(b=>b.occurrence_id===o.id&&b.status!=='cancelled');
  const activeSeats=roster.filter(b=>['booked','attended'].includes(b.status));
  const booked=roster.filter(b=>b.status==='booked');
  const meta=index.get(o.id)||{},future=new Date(o.starts_at)>new Date();
  const available=passes.filter(p=>p.status==='active'&&p.kind===o.kind&&p.remaining_credits>0&&new Date(p.valid_from)<=new Date(o.starts_at)&&new Date(p.valid_until)>=new Date(o.starts_at));
  const eligible=clients.filter(c=>!c.account_deleted_at&&available.some(p=>p.client_id===c.id)&&!activeSeats.some(b=>b.client_id===c.id));
  return show(`${button('← Volver a clases','back-classes')}<div class="business-profile-header"><span class="business-class-mark" style="background:${/^#[0-9a-f]{6}$/i.test(meta.color||'')?meta.color:'#22834d'}"></span><div><h2>${esc(o.title)}</h2><p>${dateTime(o.starts_at)} · ${esc(meta.location||'Ubicación sin definir')} · ${activeSeats.length}/${o.capacity} plazas</p></div></div>
  <div class="business-360-grid"><div class="business-detail-panel"><h3>Configuración de la clase</h3>${manager&&future&&o.status==='active'?`<form data-connected="edit-occurrence" class="business-form"><input type="hidden" name="id" value="${esc(o.id)}">${input('Nombre','title',o.title,'text','required minlength="2" maxlength="120"')}${input('Inicio','start',new Date(o.starts_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Fin','end',new Date(o.ends_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Aforo','capacity',o.capacity,'number',`min="${Math.max(1,activeSeats.length)}" max="200" required`)}${input('Lugar','location',meta.location||'','text','maxlength="250"')}${input('Color','color',meta.color||'#22834d','color')}${input('Imagen (URL)','image',meta.image_url||'','url','maxlength="2000"')}<label class="connected-field">Descripción<textarea name="description" rows="3" maxlength="2000">${esc(meta.description||'')}</textarea></label><button class="connected-primary">Guardar cambios</button></form><p>${button('Cancelar clase y devolver bonos','cancel-occurrence',o.id)}</p>`:`<p>${esc(meta.description||'Sin descripción')}</p><p>Estado: ${esc(o.status)}</p>`}</div>
  <div class="business-detail-panel"><h3>Asistentes (${roster.length})</h3>${roster.map(b=>{
   const st=bookingStatusLabel[b.status]||[b.status,'neutral'];
   return `<div class="business-roster"><span class="business-avatar">${esc(initials(clients.find(c=>c.id===b.client_id)?.name))}</span>
   <div><strong>${esc(clients.find(c=>c.id===b.client_id)?.name||'Deportista')}</strong><small>${statusBadge(st[0],st[1])}</small></div>
   <div class="business-roster-actions">
   ${manager&&b.status==='booked'?`${button('Asistió','mark-booking-attended',b.id)}${button('No presentado','mark-booking-noshow',b.id)}`:''}
   ${manager&&future&&b.status==='booked'?button('Quitar','remove-booking',b.id):''}
   </div></div>`;
  }).join('')||note('Nadie inscrito todavía.')}
  ${manager&&future&&o.status==='active'?`<form data-connected="enroll-client" class="business-form"><input type="hidden" name="occurrence" value="${esc(o.id)}">${select('Cliente con bono válido','pass',eligible.flatMap(c=>available.filter(p=>p.client_id===c.id).map(p=>[p.id,`${c.name} · ${p.remaining_credits} sesiones`])))}<button class="connected-primary" ${!eligible.length||activeSeats.length>=o.capacity?'disabled':''}>Añadir participante</button></form>${note('Inscribir consume un crédito; quitar lo devuelve. Asistió / no presentado no vuelven a descontar.')}`:''}</div>
  <div class="business-detail-panel"><h3>Planificación de la sesión</h3>${note('Publica el WOD para inscritos vinculados. Sus entrenos siguen siendo individuales.')} ${manager&&booked.length?button('Preparar movimientos','publish-class-plan',o.id):''}
  ${manager&&classEditor?`<form data-connected="publish-class-plan" class="business-form"><input type="hidden" name="occurrence" value="${esc(o.id)}">${input('Título del entrenamiento','title',o.title,'text','required minlength="2" maxlength="120"')}${editorMarkup(emptyPrescription())}<label class="connected-field">Indicaciones<textarea name="instructions" rows="3" maxlength="10000"></textarea></label><button class="connected-primary" type="submit">Publicar para los inscritos vinculados</button></form>`:''}</div>
  <div class="business-detail-panel"><h3>Información</h3><p>Tipo: ${o.kind==='class'?'Clase grupal':'Cita individual'}</p><p>Repetición: ${esc(meta.repeat_rule||'Sin repetir')}</p>${meta.image_url?`<img class="business-class-image" src="${esc(meta.image_url)}" loading="lazy" alt="">`:''}</div></div>`);
 }
 const active=occurrences.filter(o=>o.status==='active');
 const [y,m]=(calendarMonth||new Date().toLocaleDateString('sv-SE').slice(0,7)).split('-').map(Number);
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const firstDay=(new Date(y,m-1,1).getDay()+6)%7;
 const countDays=new Date(y,m,0).getDate();
 const calendar=Array.from({length:firstDay+countDays},(_,i)=>i-firstDay+1).map(d=>d<1?'<span class="business-calendar-empty"></span>':`<div class="business-calendar-cell"><strong>${d}</strong>${active.filter(o=>{const date=new Date(o.starts_at);return date.getFullYear()===y&&date.getMonth()===m-1&&date.getDate()===d}).map(o=>`<button type="button" style="--class-color:${esc(index.get(o.id)?.color||'#22834d')}" class="business-calendar-event" data-action="detail-occurrence" data-id="${esc(o.id)}">${esc(new Date(o.starts_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))} ${esc(o.title)}</button>`).join('')}</div>`).join('');
 return show(`<div class="business-panel-head"><div><h2>Agenda y clases</h2><p>Calendario o listado. En el detalle: aforo, inscritos y asistencia.</p></div><div class="heading-actions">${button('Calendario','calendar-mode','','data-mode="calendar"')}${button('Lista','calendar-mode','','data-mode="list"')}</div></div>
 ${listMode==='calendar'?`<div class="business-calendar-title">${button('‹','calendar-prev')}<strong>${esc(title)}</strong>${button('›','calendar-next')}</div><div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div><div class="business-calendar-grid">${calendar}</div>`:
 `<div class="business-cards">${active.sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).map(o=>`<button class="business-class-tile" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong><small>${esc(index.get(o.id)?.location||'Sin lugar')} · ${bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended'].includes(b.status)).length}/${o.capacity} participantes</small><span class="business-tile-arrow">Gestionar →</span></button>`).join('')||'<p class="business-empty">No hay clases. Crea la primera abajo.</p>'}</div>`}
 <div class="business-360-grid"><div class="business-detail-panel"><h3>Grupos</h3>${groups.map(g=>`<button type="button" class="business-group-row" data-action="detail-group" data-id="${esc(g.id)}"><strong>${esc(g.name)}</strong><small>${esc(g.description||'')}</small><span>Gestionar →</span></button>`).join('')||note('Puedes agrupar deportistas por programa o nivel.')} ${manager?`<form data-connected="create-group" class="business-form">${input('Nuevo grupo','name','','text','required minlength="2" maxlength="100"')}${input('Descripción','description','','text','maxlength="500"')}<button class="connected-secondary">Crear grupo</button></form>`:''}</div>
 <div class="business-detail-panel"><h3>Nueva clase o cita</h3>${manager?`<form data-connected="service-occurrence" class="business-form">${select('Tipo','kind',[['class','Clase grupal'],['appointment','Cita individual']])}${input('Nombre','title','','text','required minlength="2" maxlength="120"')}${input('Inicio','start','','datetime-local','required')}${input('Fin','end','','datetime-local','required')}${input('Aforo','capacity','1','number','min="1" max="200" required')}${select('Entrenador','coach',coaches.map(c=>[c.user_id,c.label||c.user_id.slice(0,8)]))}${select('Repetición','repeat',[['none','Una vez'],['daily','Cada día'],['weekly','Cada semana'],['weekdays','Lunes a viernes']])}${input('Número de sesiones','repeatCount','1','number','min="1" max="52" required')}<button class="connected-primary">Crear sesiones</button></form>`:note('No tienes permiso para crear horarios.')}</div></div>`);
}