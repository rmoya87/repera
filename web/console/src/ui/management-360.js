import {renderSharedAthleteSessions} from './athlete-activity.js';
import {renderAthleteInsights,renderAthleteGuidanceCircle} from './athlete-insights.js';
import {editorMarkup,emptyPrescription,starterPrescription,visualPrescription,visualSessionMeta} from './workout-editor.js';
import {passProvenanceLabel} from './gym-pass-panel.js';
import {renderClientPassesPanel} from './client-passes.js';
import {renderClientChatThread} from './business-chat.js';
import {renderTrainerAgenda,todayISO} from './trainer-agenda.js';
import {pendingAthleteInvite,renderInvitationShareCard} from './invitation-share.js';
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
const CLASS_COLORS=[
 ['#22834d','Verde'],['#1d6fb8','Azul'],['#c45c12','Naranja'],
 ['#8b3a9e','Morado'],['#b91c1c','Rojo'],['#0f766e','Turquesa'],
 ['#ca8a04','Ámbar'],['#db2777','Rosa'],['#4f46e5','Índigo'],
 ['#0891b2','Cian'],['#65a30d','Lima'],['#78716c','Piedra'],
];
const colorSwatches=(selected='#22834d')=>`<fieldset class="pt-color-swatches"><legend>Color</legend>${CLASS_COLORS.map(([hex,label])=>`<label class="pt-color-swatch" title="${esc(label)}"><input type="radio" name="color" value="${esc(hex)}" ${String(selected||'#22834d').toLowerCase()===hex.toLowerCase()?'checked':''} required><span style="--swatch:${esc(hex)}"></span></label>`).join('')}</fieldset>`;
const WEEK_DAYS=[['1','L'],['2','M'],['3','X'],['4','J'],['5','V'],['6','S'],['7','D']];
/** Franjas según duración (minutos). Clave: `dow-HHMM` (p. ej. 1-0900). */
function weekSlotMinutes(durationMin=60){
 const step=Math.min(180,Math.max(15,Number(durationMin)||60));
 const start=6*60,end=22*60;
 const mins=[];
 for(let m=start;m+step<=end;m+=step)mins.push(m);
 return mins;
}
function formatSlotLabel(totalMin){
 const h=Math.floor(totalMin/60),m=totalMin%60;
 return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
}
function weekSlotKey(dow,totalMin){
 const h=Math.floor(totalMin/60),m=totalMin%60;
 return `${dow}-${String(h).padStart(2,'0')}${String(m).padStart(2,'0')}`;
}
export function weekSlotGrid(selected=new Set(),{durationMin=60,color='#22834d'}={}){
 const mins=weekSlotMinutes(durationMin);
 const accent=/^#[0-9a-fA-F]{6}$/.test(color||'')?color:'#22834d';
 const head=WEEK_DAYS.map(([,label])=>`<span>${label}</span>`).join('');
 const rows=mins.map(totalMin=>{
  const label=formatSlotLabel(totalMin);
  const cells=WEEK_DAYS.map(([dow])=>{
   const key=weekSlotKey(dow,totalMin);
   const on=selected.has(key)||selected.has(`${dow}-${String(Math.floor(totalMin/60)).padStart(2,'0')}`);
   return `<label class="pt-week-slot ${on?'is-on':''}" title="${esc(label)}" style="--slot-color:${esc(accent)}"><input type="checkbox" name="slot" value="${esc(key)}" ${on?'checked':''}><span>${esc(label.slice(0,5))}</span></label>`;
  }).join('');
  return `<div class="pt-week-row"><span class="pt-week-hour">${esc(label)}</span><div class="pt-week-cells">${cells}</div></div>`;
 }).join('');
 return `<div class="pt-week-grid" data-week-slots data-duration="${esc(durationMin)}" style="--slot-color:${esc(accent)}">
  <div class="pt-week-head"><span></span>${head}</div>
  ${rows}
 </div>`;
}
export function parseWeekSlotKey(key){
 const m=String(key||'').match(/^([1-7])-(\d{2})(\d{2})?$/);
 if(!m)return null;
 return {isoDow:Number(m[1]),hour:Number(m[2]),minute:Number(m[3]||'0')};
}

function renderTrainerOverview({clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView='month',agendaDay='',gymAssignments=[],requestCount=0}){
 return renderTrainerAgenda({
  clients,occurrences,bookings,sessions,gymAssignments,calendarMonth,agendaView,agendaDay,manager,
  mode:'home',requestCount,
 });
}

function pendingEnrollmentRequests(requests=[]){
 const list=Array.isArray(requests)?requests:[];
 return list.filter(r=>!r.status||r.status==='pending');
}
function renderGymHome({clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView='month',agendaDay='',coaches=[],requestCount=0,details=[],roomFilter='',expandedOccurrenceId=''}){
 return renderTrainerAgenda({
  clients,occurrences,bookings,sessions,gymAssignments:[],calendarMonth,agendaView,agendaDay,manager,
  mode:'home',requestCount,coaches,variant:'gym',details,roomFilter,expandedOccurrenceId,
 });
}

export function renderBusinessHome({org,clients=[],occurrences=[],bookings=[],sessions=[],templates=[],requests=[],manager=false,calendarMonth='',passes=[],groups=[],busy=false,escapeHTML=esc,agendaView='month',agendaDay='',gymAssignments=[],coaches=[],details=[],roomFilter='',expandedOccurrenceId=''}){
 const waiting=pendingEnrollmentRequests(requests);
 if(org?.kind==='personal_trainer'){
  return renderTrainerOverview({clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView,agendaDay,gymAssignments,requestCount:waiting.length});
 }
 return renderGymHome({clients,occurrences,bookings,sessions,calendarMonth,manager,agendaView,agendaDay,coaches,requestCount:waiting.length,details,roomFilter,expandedOccurrenceId});
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
export function renderClient360({clients=[],selected=null,passes=[],offers=[],bookings=[],occurrences=[],sessions=[],notices=[],chatMessages=[],sharedHistory=[],attendance=[],passEvents=[],trainerActivityMonth='',trainerActivityDay='',manager=false,role='',trainer=false,busy=false,escapeHTML=esc,clientSection='training',clientQuery='',gymAssignments=[],agendaView='month',agendaDay='',calendarMonth='',invitations=[],orgId='',inviteShare=null,org=null,groups=[],groupMembers=[],details=[],coaches=[]}){
 if(!selected){
  const q=String(clientQuery||'').trim().toLowerCase();
  const filtered=clients.filter(c=>{
   if(!q)return true;
   const hay=((c.name||'')+' '+(c.email||'')).toLowerCase();
   return hay.includes(q);
  });
  const peopleLabel=trainer?'Clientes':'Socios';
  const groupsBlock=`<div class="business-detail-panel pt-groups-panel"><div class="business-panel-head"><div>
  <h3>Grupos para avisos</h3>
  <p class="connected-hint">Listas de ${trainer?'clientes':'socios'} para mensajes (nivel/programa). No son clases del calendario.</p></div>
  ${manager?button('+ Grupo','open-new-group-modal'):''}</div>
  ${groups.map(g=>{
   const n=groupMembers.filter(x=>x.group_id===g.id).length;
   return `<button type="button" class="business-group-row" data-action="detail-group" data-id="${esc(g.id)}"><strong>${esc(g.name)}</strong><small>${esc(g.description||`${n} miembro${n===1?'':'s'}`)}</small><span>Gestionar →</span></button>`;
  }).join('')||note(manager?'Crea un grupo solo si quieres avisar a un subconjunto.':'Sin grupos.')}
  </div>`;
  return show(`<div class="business-panel-head pt-clients-head"><div>
 <h2>${peopleLabel}</h2></div>
 ${manager?primary(trainer?'Invitar cliente':'Invitar socio','open-invite-modal'):''}</div>
 <label class="connected-field pt-client-search">Buscar
  <input type="search" data-client-filter value="${esc(clientQuery||'')}" placeholder="Nombre o correo" autocomplete="off">
 </label>
 <div class="business-client-table-wrap"><table class="business-client-table"><thead><tr>
 <th>${trainer?'Cliente':'Socio'}</th><th>Correo</th><th>Vinculación</th><th>Bono</th><th></th></tr></thead><tbody>
 ${filtered.map(c=>{
  const p=passes.filter(x=>x.client_id===c.id&&x.status==='active').sort((a,b)=>b.remaining_credits-a.remaining_credits)[0];
  return `<tr role="link" tabindex="0" data-action="detail-client" data-id="${esc(c.id)}">
 <td><div class="business-client-person"><span class="business-avatar">${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?
 `<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}</span>
 <strong>${esc(c.name)}</strong></div></td><td>${esc(c.email||'—')}</td>
 <td>${c.account_deleted_at?'Histórico':c.user_id?'Vinculado':statusBadge('Pendiente','info')}</td>
 <td>${p?(p.remaining_credits>=9000?'Ilimitado':`${p.remaining_credits}/${p.total_credits}`):'—'}</td>
 <td>${manager&&!c.user_id&&!c.account_deleted_at?`<button type="button" class="connected-secondary" data-action="invite-client" data-id="${esc(c.id)}" onclick="event.stopPropagation()">Invitar</button>`:''}</td></tr>`;}).join('')||
 `<tr><td colspan="5"><p class="business-empty">Todavía no hay ${trainer?'clientes':'socios'}. Invita al primero.</p></td></tr>`}
 </tbody></table></div>${groupsBlock}`);
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
 // Agenda fusionada en Entrenamientos; Mensajes y Datos aparte.
 // Gym: Entrenamientos = calendario de clases (como Inicio) + crear entreno. Sin pestaña Reservas.
 const tabDefs=[['training','Entrenamientos'],['passes','Bonos'],['chat','Mensajes'],['data','Datos']];
 const section=tabDefs.some(([id])=>id===clientSection)?clientSection:(clientSection==='agenda'||clientSection==='bookings'?'training':clientSection);
 const safeSection=tabDefs.some(([id])=>id===section)?section:'training';
 const tabs=`<nav class="business-client-tabs" aria-label="Ficha de cliente">
 ${tabDefs.map(([id,name])=>
 `<button type="button" data-action="client-section" data-section="${id}" class="${safeSection===id?'active':''}"
 aria-current="${safeSection===id?'page':'false'}">${name}</button>`).join('')}</nav>`;
 const linkLabel=archived?'Cuenta eliminada':c.user_id?'Vinculado':'Invitación pendiente';
 const pendingInvite=!archived&&!c.user_id?pendingAthleteInvite({invitations,orgId,email:c.email}):null;
 const shareInvite=pendingInvite
  ||(inviteShare?.invitationId&&String(inviteShare.email||'').toLowerCase()===String(c.email||'').toLowerCase()
   ?{id:inviteShare.invitationId,email:inviteShare.email}:null);
 const head=`${!archived&&manager&&!c.user_id&&!shareInvite?`<div class="pt-client-topbar pt-client-topbar-slim">
  <div class="pt-client-top-actions">${button('Crear invitación','invite-client',c.id)}</div>
 </div>`:''}
 <div class="business-profile-header pt-profile-header">
 <span class="business-avatar large">
 ${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?`<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}
 </span>
 <div class="pt-profile-main"><h2>${esc(c.name)}</h2>
 <p>${esc(c.email||'—')} · ${statusBadge(linkLabel,archived?'muted':c.user_id?'ok':'info')}
 ${activePass?` · ${activePass.remaining_credits>=9000?'Ilimitado':`${activePass.remaining_credits}/${activePass.total_credits}`} · ${passProvenanceLabel(activePass)}`:''}
 ${nextBooking?` · Próximo: ${esc(nextBooking.o.title)} ${dateTime(nextBooking.o.starts_at)}`:''}</p>
 </div>
 ${renderAthleteGuidanceCircle(logged,sharedHistory.length)}
 </div>`;
 let body='';
 if(safeSection==='training'){
  // Gym: todas las clases (como Inicio) + estado de inscripción del socio. PT: agenda propia.
  const classOcc=trainer
   ?occurrences.filter(o=>o.status==='active'&&(ownBookings.some(b=>b.occurrence_id===o.id)||o.kind==='appointment'))
   :occurrences.filter(o=>o.status==='active'&&o.kind==='class');
  body=`<div class="pt-client-agenda">
   ${renderTrainerAgenda({
    clients:trainer?[c]:clients,occurrences:classOcc,bookings,
    sessions:ownSessions,gymAssignments:[],details,coaches,
    calendarMonth:calendarMonth||trainerActivityMonth,agendaView:trainer?agendaView:'month',
    agendaDay:agendaDay||trainerActivityDay||todayISO(),
    manager,mode:'client',clientId:c.id,clientName:c.name,archived,
    variant:trainer?'trainer':'gym',
   })}
   ${logged.length?`<section class="connected-card pt-client-history"><h3>Actividad compartida</h3>
     ${logged.some(w=>(w.exercises||[]).length)?renderAthleteInsights(logged,sharedHistory.length,{showGuidance:false}):''}
     ${renderSharedAthleteSessions(sharedHistory)}</section>`:
     '<section class="connected-card"><p class="business-empty">Sin actividad compartida todavía.</p></section>'}
  </div>`;
 }
 if(safeSection==='chat'){
  body=`<div class="pt-chat-shell business-detail-panel">
  ${renderClientChatThread({messages:chatMessages,clientId:c.id,busy})}</div>`;
 }
 if(safeSection==='passes'){
  body=renderClientPassesPanel({
   client:c,passes,offers,attendance,bookings,occurrences,passEvents,
   manager,trainer,busy,archived,
  });
 }
 if(safeSection==='data'){
  const inviteBlock=manager&&shareInvite
   ?renderInvitationShareCard({
    invitationId:shareInvite.id,
    email:c.email||shareInvite.email||'',
    sent:!!inviteShare?.sent&&inviteShare.invitationId===shareInvite.id,
    reason:inviteShare?.invitationId===shareInvite.id?(inviteShare.reason||''):'',
    compact:true,
   })
   :(manager&&!archived&&!c.user_id
    ?`<section class="connected-card business-invite-share is-pending"><p>Todavía no hay invitación. Pulsa <strong>Crear invitación</strong> arriba.</p></section>`
    :'');
  body=`${inviteBlock}<div class="pt-data-card business-detail-panel">
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
 return show(head+tabs+body);
}
export function renderClasses360({occurrences=[],clients=[],bookings=[],passes=[],details=[],groups=[],groupMembers=[],selectedGroup=null,coaches=[],selected=null,classEditor=false,listMode='calendar',calendarMonth='',activeClient=null,manager=false,escapeHTML=esc}){
 const index=new Map(details.map(d=>[d.occurrence_id,d]));
 if(selectedGroup){
  const g=groups.find(g=>g.id===selectedGroup);
  if(!g)return show('<p>Grupo no encontrado.</p>');
  const members=new Set(groupMembers.filter(x=>x.group_id===selectedGroup).map(x=>x.client_id));
  return show(`${button('← Volver','back-groups')}<div class="business-profile-header"><span class="business-avatar large">${esc(initials(g.name))}</span><div><h2>${esc(g.name)}</h2><p>${members.size} deportistas · avisos</p></div></div>
  ${manager?`<form data-connected="edit-group" class="business-form"><input type="hidden" name="group" value="${esc(g.id)}">
   ${input('Nombre del grupo','name',g.name,'text','required minlength="2" maxlength="100"')}
   ${input('Descripción','description',g.description||'','text','maxlength="500"')}
   <h3>Participantes</h3><div class="business-group-members">${clients.map(c=>`<label><input type="checkbox" name="members" value="${esc(c.id)}" ${members.has(c.id)?'checked':''}><span class="business-avatar">${esc(initials(c.name))}</span><strong>${esc(c.name)}</strong></label>`).join('')}</div>
   <div class="pt-day-tools"><button class="connected-primary" type="submit">Guardar</button>
    <button type="button" class="connected-secondary" data-action="delete-group" data-id="${esc(g.id)}">Borrar grupo</button></div></form>`:
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
  <div class="business-360-grid"><div class="business-detail-panel"><h3>Configuración de la clase</h3>${manager&&future&&o.status==='active'?`<form data-connected="edit-occurrence" class="business-form"><input type="hidden" name="id" value="${esc(o.id)}">${input('Nombre','title',o.title,'text','required minlength="2" maxlength="120"')}${input('Inicio','start',new Date(o.starts_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Fin','end',new Date(o.ends_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Aforo','capacity',o.capacity,'number',`min="${Math.max(1,activeSeats.length)}" max="200" required`)}${input('Lugar','location',meta.location||'','text','maxlength="250"')}${colorSwatches(meta.color||'#22834d')}${input('Imagen (URL)','image',meta.image_url||'','url','maxlength="2000"')}<label class="connected-field">Descripción<textarea name="description" rows="3" maxlength="2000">${esc(meta.description||'')}</textarea></label><button class="connected-primary">Guardar cambios</button></form><p>${button('Cancelar clase y devolver bonos','cancel-occurrence',o.id)}</p>`:`<p>${esc(meta.description||'Sin descripción')}</p><p>Estado: ${esc(o.status)}</p>`}</div>
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
  <div class="business-detail-panel"><h3>Entreno de la clase</h3>
  ${note('Puedes crear un entreno nuevo o usar una plantilla de Mis entrenos. Los inscritos con app lo verán en el detalle y podrán Comenzarlo. Quitar entreno solo afecta a esta clase (no borra plantillas de Mis entrenos).')}
  ${(()=>{
    const blocks=(visualPrescription(meta.prescription||emptyPrescription()).blocks||[]);
    const hasPlan=blocks.length>0;
    const summary=hasPlan
      ?`<p><strong>${esc(meta.training_title||o.title)}</strong> · ${blocks.length} bloque${blocks.length===1?'':'s'}</p>`
      :note(meta.training_title?'Sin bloques todavía.':'Todavía no hay entreno asociado.');
    if(!(manager&&future&&o.status==='active'))return summary;
    return `${summary}<div class="pt-gym-action-row">
      ${primary(hasPlan?'Editar entreno':'Crear / asociar entreno','publish-class-plan',o.id)}
      ${hasPlan?`<button type="button" class="connected-secondary pt-danger-btn" data-action="clear-class-plan" data-id="${esc(o.id)}">Quitar entreno</button>`:''}
     </div>`;
  })()}
  </div>
  <div class="business-detail-panel"><h3>Información</h3><p>Tipo: ${o.kind==='class'?'Clase grupal':'Cita individual'}</p><p>Repetición: ${esc(meta.repeat_rule||'Sin repetir')}</p>${meta.image_url?`<img class="business-class-image" src="${esc(meta.image_url)}" loading="lazy" alt="">`:''}</div></div>`);
 }
 const active=occurrences.filter(o=>o.status==='active');
 const [y,m]=(calendarMonth||new Date().toLocaleDateString('sv-SE').slice(0,7)).split('-').map(Number);
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const firstDay=(new Date(y,m-1,1).getDay()+6)%7;
 const countDays=new Date(y,m,0).getDate();
 const calendar=Array.from({length:firstDay+countDays},(_,i)=>i-firstDay+1).map(d=>d<1?'<span class="business-calendar-empty"></span>':`<div class="business-calendar-cell"><strong>${d}</strong>${active.filter(o=>{const date=new Date(o.starts_at);return date.getFullYear()===y&&date.getMonth()===m-1&&date.getDate()===d}).map(o=>`<button type="button" style="--class-color:${esc(index.get(o.id)?.color||'#22834d')}" class="business-calendar-event" data-action="detail-occurrence" data-id="${esc(o.id)}">${esc(new Date(o.starts_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))} ${esc(o.title)}</button>`).join('')}</div>`).join('');
 return show(`<div class="business-panel-head"><div><h2>Agenda</h2><p>Calendario o listado. En el detalle: aforo, inscritos y asistencia.</p></div>
 <div class="heading-actions">
  ${button('Calendario','calendar-mode','','data-mode="calendar"')}
  ${button('Lista','calendar-mode','','data-mode="list"')}
  ${manager?primary('Nueva clase','open-new-class-modal'):''}
 </div></div>
 ${listMode==='calendar'?`<div class="business-calendar-title">${button('‹','calendar-prev')}<strong>${esc(title)}</strong>${button('›','calendar-next')}</div><div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div><div class="business-calendar-grid">${calendar}</div>`:
 `<div class="business-cards">${active.sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).map(o=>{
  const color=/^#[0-9a-f]{6}$/i.test(index.get(o.id)?.color||'')?index.get(o.id).color:'#22834d';
  return `<button class="business-class-tile" style="--class-color:${esc(color)}" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-swatch" aria-hidden="true"></span><span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong><small>${esc(index.get(o.id)?.location||'Sin lugar')} · ${bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended'].includes(b.status)).length}/${o.capacity} · ${esc(coaches.find(c=>c.user_id===o.coach_user_id)?.label||'Sin entrenador')}</small><span class="business-tile-arrow">Gestionar →</span></button>`;
 }).join('')||'<p class="business-empty">No hay clases. Crea la primera con «Nueva clase».</p>'}</div>`}
 <div class="business-detail-panel"><div class="business-panel-head"><div><h3>Clases próximas</h3></div>
  ${manager?button('+ Clase','open-new-class-modal'):''}</div>
  ${active.filter(o=>new Date(o.starts_at)>=new Date()).sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).slice(0,8).map(o=>{
   const color=/^#[0-9a-f]{6}$/i.test(index.get(o.id)?.color||'')?index.get(o.id).color:'#22834d';
   return `<button type="button" class="business-group-row business-class-row" style="--class-color:${esc(color)}" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-swatch" aria-hidden="true"></span><strong>${esc(o.title)}</strong><small>${dateTime(o.starts_at)} · ${esc(coaches.find(c=>c.user_id===o.coach_user_id)?.label||'Sin entrenador')}</small><span>Abrir →</span></button>`;
  }).join('')||note(manager?'Crea la primera clase con el botón Nueva clase.':'Sin clases programadas.')}
 </div>`);
}

/** Modal crear grupo (listas para avisos; vive en Socios/Clientes). */
export function renderEnrollClassModal({occurrence=null,clients=[],passes=[],busy=false}={}){
 if(!occurrence)return '';
 const available=passes.filter(p=>p.status==='active'&&p.kind==='class'&&p.remaining_credits>0&&Date.parse(p.valid_until)>Date.now());
 const eligible=clients.filter(c=>!c.account_deleted_at&&available.some(p=>p.client_id===c.id));
 const opts=eligible.flatMap(c=>available.filter(p=>p.client_id===c.id).map(p=>[p.id,`${c.name} · ${p.remaining_credits} ses.`]));
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet" role="dialog" aria-modal="true" aria-label="Añadir participante">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Clase</span><h2>Añadir participante</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <p class="connected-hint">${esc(occurrence.title)} · ${esc(new Date(occurrence.starts_at).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}))}</p>
   <form data-connected="enroll-client" class="business-form pt-sheet-form">
    <input type="hidden" name="occurrence" value="${esc(occurrence.id)}">
    ${select('Socio con bono válido','pass',opts.length?opts:[['','Sin bonos disponibles']])}
    <button type="submit" class="connected-primary" ${!opts.length||busy?'disabled':''}>Inscribir</button>
   </form>
  </div>
 </section></div>`;
}

export function renderNewGroupModal({busy=false}={}){
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet" role="dialog" aria-modal="true" aria-label="Nuevo grupo">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Avisos</span><h2>Nuevo grupo</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <div class="pt-sheet-hero"><p>Lista de personas para enviar avisos. <strong>No crea clases</strong> en la agenda.</p></div>
   <form data-connected="create-group" class="business-form pt-sheet-form">
    ${input('Nombre','name','','text','required minlength="2" maxlength="100"')}
    ${input('Descripción','description','','text','maxlength="500"')}
    <button type="submit" class="connected-primary" ${busy?'disabled':''}>Crear grupo</button>
   </form>
  </div>
 </section></div>`;
}

/** Modal nueva clase: única (fecha/hora/duración) o repetitiva (semana tipo). */
export function renderNewClassModal({coaches=[],busy=false,day=''}={}){
 const staff=coaches.filter(c=>c.user_id&&!/Administrador Repera/i.test(c.label||''));
 const seed=new Set();
 const today=new Date().toLocaleDateString('sv-SE');
 const seedDay=/^\d{4}-\d{2}-\d{2}$/.test(day)?day:today;
 if(/^\d{4}-\d{2}-\d{2}$/.test(day)){
  const d=new Date(day+'T12:00:00');
  const iso=d.getDay()||7;
  seed.add(weekSlotKey(iso,9*60));
 }
 const uniqueStart=`${seedDay}T09:00`;
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-new-class-dialog" role="dialog" aria-modal="true" aria-label="Nueva clase">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Agenda</span><h2>Nueva clase</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <form data-connected="service-occurrence" class="business-form pt-sheet-form" data-class-create data-class-week-create>
    <input type="hidden" name="kind" value="class">
    ${input('Nombre de la clase','title','','text','required minlength="2" maxlength="120" placeholder="Spinning · HIIT · Yoga…"')}
    ${colorSwatches('#22834d')}
    <label class="connected-field">Tipo
     <select name="scheduleMode" data-class-schedule-mode>
      <option value="unique" selected>Clase única</option>
      <option value="weekly">Repetitiva</option>
     </select>
    </label>
    <div class="pt-sheet-grid">
     <label class="connected-field">Duración (min)
      <input name="duration" type="number" min="15" max="240" step="5" value="60" required data-week-duration>
     </label>
     ${input('Aforo','capacity','12','number','min="1" max="200" required')}
    </div>
    <label class="connected-field">Entrenador (opcional)
     <select name="coach">
      <option value="">Sin asignar</option>
      ${staff.map(c=>`<option value="${esc(c.user_id)}">${esc(c.label||c.user_id.slice(0,8))}</option>`).join('')}
     </select>
    </label>
    ${input('Sala / ubicación (opcional)','location','','text','maxlength="250"')}
    <div data-class-panel="unique">
     <div class="pt-sheet-grid">
      ${input('Fecha y hora','start',uniqueStart,'datetime-local','required')}
     </div>
    </div>
    <div data-class-panel="weekly" hidden>
     <div class="pt-sheet-grid">
      ${input('Comienza el','seriesStart',seedDay,'date','required')}
     </div>
     <fieldset class="pt-until-field">
      <legend>Fin de la serie</legend>
      <div class="pt-until-options">
       <label class="pt-radio-card"><input type="radio" name="untilMode" value="indefinite" checked>
        <span><strong>Sin fecha de fin</strong></span></label>
       <label class="pt-radio-card"><input type="radio" name="untilMode" value="date">
        <span><strong>Hasta una fecha</strong>
         <input name="untilDate" type="date" min="${esc(today)}">
        </span></label>
      </div>
     </fieldset>
     <div class="connected-field pt-week-slot-field" data-week-slot-host>
      <span>Días y franjas</span>
      ${weekSlotGrid(seed,{durationMin:60,color:'#22834d'})}
     </div>
    </div>
    <label class="connected-field">Notas (opcional)<textarea name="description" rows="2" maxlength="2000"></textarea></label>
    <button type="submit" class="connected-primary" ${busy?'disabled':''}>Crear en el calendario</button>
   </form>
  </div>
 </section></div>`;
}

/** Modal: asociar / crear entreno de una clase (plantilla Mis entrenos o editor). */
export function renderPublishClassPlanModal({
 occurrence=null,detail={},busy=false,seedPrescription=null,templates=[],templateId='',
 occurrences=[],details=[],assignScope='one',
}={}){
 if(!occurrence)return '';
 const day=new Date(occurrence.starts_at).toLocaleDateString('sv-SE');
 const pool=occurrences.length?occurrences:[occurrence];
 const dets=details.length?details:[detail];
 return renderAssignClassTrainingModal({
  day,
  occurrences:pool,
  details:dets,
  templates,
  preselectedIds:[occurrence.id],
  busy,
  seedPrescription:seedPrescription||detail.prescription||null,
  titleSeed:detail.training_title||occurrence.title||'',
  instructionsSeed:detail.training_instructions||'',
  templateId,
  lockSelection:true,
  assignScope,
 });
}

/**
 * Asignar un entreno a una o varias clases del día (checkboxes + plantilla / editor).
 * @param {{day:string,occurrences:object[],details?:object[],templates?:object[],preselectedIds?:string[],onlyWithoutPlan?:boolean,busy?:boolean,seedPrescription?:object|null,titleSeed?:string,instructionsSeed?:string,lockSelection?:boolean,templateId?:string,assignScope?:string}} opts
 */
export function renderAssignClassTrainingModal({
 day='',
 occurrences=[],
 details=[],
 templates=[],
 preselectedIds=[],
 onlyWithoutPlan=false,
 busy=false,
 seedPrescription=null,
 titleSeed='',
 instructionsSeed='',
 lockSelection=false,
 templateId='',
 assignScope='one',
}={}){
 const detailMap=new Map((details||[]).map(d=>[d.occurrence_id,d]));
 const hasPlan=o=>{
  const d=detailMap.get(o.id)||{};
  const p=d.prescription;
  return Boolean(p&&(p.schemaVersion===1||p.version===1)&&Array.isArray(p.blocks)&&p.blocks.length>0);
 };
 const now=Date.now();
 // Edición de una sola clase: no filtrar por «futuro» hasta pintar el aviso;
 // el guardado sigue bloqueado si ya empezó.
 const eligible=(occurrences||[]).filter(o=>{
  if(o.kind!=='class'||o.status!=='active')return false;
  if(day&&new Date(o.starts_at).toLocaleDateString('sv-SE')!==day)return false;
  if(lockSelection)return true;
  return new Date(o.starts_at).getTime()>now;
 });
 const futureActive=eligible.filter(o=>new Date(o.starts_at).getTime()>now);
 const listed=onlyWithoutPlan?futureActive.filter(o=>!hasPlan(o))
  :(lockSelection?eligible:futureActive);
 const selected=new Set(
  (preselectedIds||[]).filter(id=>listed.some(o=>o.id===id))
 );
 if(!selected.size&&listed.length&&!lockSelection){
  listed.forEach(o=>selected.add(o.id));
 }
 if(lockSelection&&listed[0])selected.add(listed[0].id);
 const seedTpl=templates.find(t=>t.id===templateId);
 const rawSeed=seedPrescription||seedTpl?.prescription||null;
 const seed=rawSeed?visualPrescription(rawSeed):starterPrescription();
 const title=titleSeed||seedTpl?.name||(listed[0]?.title||'Entreno del día');
 const dayLabel=day
  ?new Date(day+'T12:00:00').toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'})
  :'Clases seleccionadas';
 const target=listed[0]||null;
 const targetEditable=Boolean(target&&new Date(target.starts_at).getTime()>now);
 const targetHasPlan=Boolean(target&&hasPlan(target));
 const replacing=[...selected].some(id=>hasPlan({id}))||targetHasPlan;
 const list=listed.length?listed.map(o=>{
  const d=detailMap.get(o.id)||{};
  const planned=hasPlan(o);
  const time=new Date(o.starts_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'});
  const loc=d.location?` · ${d.location}`:'';
  const started=new Date(o.starts_at).getTime()<=now;
  return `<label class="pt-assign-class-row ${planned?'has-plan':''}">
   <input type="checkbox" name="occurrences" value="${esc(o.id)}" ${selected.has(o.id)?'checked':''} ${lockSelection||started?'disabled':''}>
   <span><strong>${esc(o.title)}</strong><small>${esc(time)}${esc(loc)} · ${started?'Ya empezó':(planned?'Con entreno':'Sin entreno')}</small></span>
  </label>`;
 }).join(''):'<p class="business-empty">No hay clases futuras en este día.</p>';
 const tplOptions=[['','Crear ahora (editor abajo)'],
  ...templates.map(t=>[t.id,`${t.name} · ${(visualPrescription(t.prescription).blocks||[]).length} bloq.`])];
 const scopeField=replacing&&targetEditable?`<fieldset class="pt-assign-scope"><legend>Alcance al guardar</legend>
  <label class="pt-radio-card"><input type="radio" name="assignScope" value="one" ${assignScope==='one'?'checked':''}>
   <span><strong>Esta clase</strong><small>Solo la selección actual</small></span></label>
  <label class="pt-radio-card"><input type="radio" name="assignScope" value="series" ${assignScope==='series'?'checked':''}>
   <span><strong>Esta serie (futuras)</strong><small>Mismo título, día y hora hacia delante</small></span></label>
  <label class="pt-radio-card"><input type="radio" name="assignScope" value="day" ${assignScope==='day'?'checked':''}>
   <span><strong>Todas las del día</strong><small>Clases futuras de ${esc(dayLabel)}</small></span></label>
 </fieldset>`:`<input type="hidden" name="assignScope" value="one">`;
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-workout-dialog" role="dialog" aria-modal="true" aria-label="Asignar entreno a clases">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Clases</span><h2>${lockSelection?(replacing?'Editar entreno de la clase':'Entreno de la clase'):'Asignar entreno'}</h2></div>
  <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <p class="connected-hint">${esc(dayLabel)}. Elige un entreno de Mis entrenos o créalo aquí; el plan llega a los inscritos con app.</p>
   ${lockSelection&&target&&!targetEditable?'<p class="connected-error" role="alert">Esta clase ya ha empezado: no se puede editar ni quitar el entreno.</p>':''}
   <form data-connected="publish-class-plan-bulk" class="business-form pt-sheet-form" data-assign-class-form>
    <input type="hidden" name="day" value="${esc(day)}">
    ${lockSelection&&target?`<input type="hidden" name="occurrences" value="${esc(target.id)}">`:''}
    ${!lockSelection?`<fieldset class="pt-assign-class-list"><legend>Clases del día</legend>
     <label class="pt-assign-filter"><input type="checkbox" name="onlyWithout" value="1" data-action="assign-only-without" ${onlyWithoutPlan?'checked':''}> Solo las que aún no tienen entreno</label>
     <div class="pt-assign-class-checks">${list}</div>
     ${listed.length?`<div class="pt-assign-quick">
      <button type="button" class="connected-secondary" data-action="assign-select-all">Todas</button>
      <button type="button" class="connected-secondary" data-action="assign-select-none">Ninguna</button>
     </div>`:''}
    </fieldset>`:''}
    <fieldset class="pt-assign-origin"><legend>Origen del entreno</legend>
     ${templates.length?select('Usar Mis entrenos o crear ahora','templateId',tplOptions,templateId)
      :'<p class="connected-hint">Aún no hay plantillas: crea el entreno abajo o guarda uno en Mis entrenos.</p>'}
    </fieldset>
    ${scopeField}
    ${input('Título del entrenamiento','title',title,'text','required minlength="2" maxlength="120"')}
    ${editorMarkup(seed,{meta:visualSessionMeta(rawSeed||{}),showMeta:true})}
    <label class="connected-field">Indicaciones<textarea name="instructions" rows="3" maxlength="10000">${esc(instructionsSeed)}</textarea></label>
    <button type="submit" class="connected-primary" ${busy||!listed.length||(lockSelection&&!targetEditable)?'disabled':''}>${lockSelection?'Guardar entreno de la clase':'Asignar a las clases marcadas'}</button>
   </form>
   ${lockSelection&&targetHasPlan&&targetEditable?`<div class="pt-class-danger pt-class-danger-row">
     <button type="button" class="connected-secondary pt-danger-btn" data-action="clear-class-plan" data-id="${esc(target.id)}" ${busy?'disabled':''}>Quitar entreno de la clase</button>
    </div>`:''}
  </div>
 </section></div>`;
}

/** Editar clase existente: este evento o toda la serie (estilo Outlook). */
export function renderEditClassModal({occurrence=null,detail={},coaches=[],busy=false}={}){
 if(!occurrence)return '';
 const staff=coaches.filter(c=>c.user_id&&!/Administrador Repera/i.test(c.label||''));
 const start=new Date(occurrence.starts_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16);
 const end=new Date(occurrence.ends_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16);
 const future=new Date(occurrence.starts_at)>new Date();
 const blocked=occurrence.status==='cancelled';
 const isSeries=String(detail.repeat_rule||'none')!=='none';
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-new-class-dialog" role="dialog" aria-modal="true" aria-label="Editar clase">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Agenda</span><h2>Editar clase</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   ${blocked?'<p class="connected-hint">Esta clase está cancelada: permanece en el calendario bloqueada y no admite nuevas inscripciones.</p>':''}
   <form data-connected="edit-occurrence" class="business-form pt-sheet-form">
    <input type="hidden" name="id" value="${esc(occurrence.id)}">
    ${isSeries?`<fieldset class="pt-edit-scope">
     <legend>¿Qué quieres cambiar?</legend>
     <label class="pt-radio-card"><input type="radio" name="editScope" value="one" checked>
      <span><strong>Solo este evento</strong><small>${esc(new Date(occurrence.starts_at).toLocaleString('es-ES',{dateStyle:'full',timeStyle:'short'}))}</small></span></label>
     <label class="pt-radio-card"><input type="radio" name="editScope" value="series">
      <span><strong>Este y los siguientes</strong><small>Mismo nombre, día de la semana y hora (como Outlook)</small></span></label>
    </fieldset>`:`<input type="hidden" name="editScope" value="one">`}
    ${input('Nombre de la clase','title',occurrence.title||'','text','required minlength="2" maxlength="120"')}
    ${colorSwatches(detail.color||'#22834d')}
    <div class="pt-sheet-grid">
     ${input('Inicio','start',start,'datetime-local','required')}
     ${input('Fin','end',end,'datetime-local','required')}
    </div>
    ${input('Aforo','capacity',occurrence.capacity||12,'number',`min="1" max="200" required`)}
    <label class="connected-field">Entrenador (opcional)
     <select name="coach" disabled title="El cambio de entrenador se gestiona al crear la serie">
      <option value="">${occurrence.coach_user_id?'Asignado':'Sin asignar'}</option>
      ${staff.map(c=>`<option value="${esc(c.user_id)}" ${c.user_id===occurrence.coach_user_id?'selected':''}>${esc(c.label||c.user_id.slice(0,8))}</option>`).join('')}
     </select>
    </label>
    ${input('Sala / ubicación','location',detail.location||'','text','maxlength="250"')}
    <label class="connected-field">Notas<textarea name="description" rows="2" maxlength="2000">${esc(detail.description||'')}</textarea></label>
    <input type="hidden" name="image" value="${esc(detail.image_url||'')}">
    <button type="submit" class="connected-primary" ${busy||!future?'disabled':''}>Guardar cambios</button>
   </form>
   ${future&&!blocked?`<div class="pt-class-danger pt-class-danger-row">
     <button type="button" class="connected-secondary" data-action="cancel-occurrence" data-id="${esc(occurrence.id)}">Cancelar clase</button>
     <button type="button" class="connected-secondary pt-danger-btn" data-action="delete-occurrence" data-id="${esc(occurrence.id)}">Borrar</button>
    </div>`:''}
   ${future&&blocked?`<div class="pt-class-danger pt-class-danger-row">
     <button type="button" class="connected-secondary pt-danger-btn" data-action="delete-occurrence" data-id="${esc(occurrence.id)}">Borrar del calendario</button>
    </div>`:''}
  </div>
 </section></div>`;
}