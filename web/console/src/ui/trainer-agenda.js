// Agenda PT: vista mes / día (inicio y ficha de cliente), citas + entrenos + clases gym.
import {MOVEMENTS,exerciseThumbHTML,visualPrescription} from './workout-editor.js';
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const dayLabel=iso=>new Date(iso+'T12:00:00').toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'});
const timeOf=iso=>iso?new Date(iso).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}):'';
const dateTime=iso=>iso?new Date(iso).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}):'—';

export function todayISO(){return new Date().toLocaleDateString('sv-SE');}

export function collectDayEvents({
 day,clients=[],occurrences=[],bookings=[],sessions=[],gymAssignments=[],coaches=[],
 details=[],roomFilter='',includeCancelled=false,focusClientId='',
}){
 const people=Object.fromEntries(clients.map(c=>[c.id,c.name]));
 const coachMap=Object.fromEntries(coaches.map(c=>[c.user_id,c.label||c.user_id?.slice(0,8)]));
 const detailMap=Object.fromEntries((details||[]).map(d=>[d.occurrence_id,d]));
 const room=String(roomFilter||'').trim().toLowerCase();
 const events=[];
 const occStatuses=includeCancelled?['active','cancelled']:['active'];
 for(const o of occurrences.filter(o=>occStatuses.includes(o.status)&&o.status!=='deleted'&&new Date(o.starts_at).toLocaleDateString('sv-SE')===day)){
  const meta=detailMap[o.id]||{};
  const location=String(meta.location||'').trim();
  if(room&&location.toLowerCase()!==room)continue;
  const booked=bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended','waitlist'].includes(b.status));
  const activeBooked=booked.filter(b=>['booked','attended'].includes(b.status));
  const names=activeBooked.map(b=>people[b.client_id]).filter(Boolean);
  const coach=coachMap[o.coach_user_id]||'';
  const clientBooking=focusClientId
   ?booked.find(b=>b.client_id===focusClientId)
   :null;
  const who=o.kind==='appointment'
   ?(names[0]?`con ${names[0]}`:'sin cliente asignado')
   :`${activeBooked.length}/${o.capacity} plazas`;
  const coachBit=coach?` · ${coach}`:'';
  const blocked=o.status==='cancelled';
  events.push({
   sort:o.starts_at,kind:o.kind==='appointment'?'cita':'grupo',
   title:o.title,
   subtitle:blocked
    ?`${timeOf(o.starts_at)} · Cancelada (bloqueada)`
    :`${timeOf(o.starts_at)} · ${who}${coachBit}${clientBooking?` · ${clientBooking.status==='waitlist'?'En lista':'Apuntado'}`:''}`,
   action:'detail-occurrence',id:o.id,source:'own',
   clientId:o.kind==='appointment'?activeBooked[0]?.client_id:'',
   coachLabel:coach,
   color:meta.color||'#22834d',
   location,
   capacity:o.capacity,
   bookedCount:activeBooked.length,
   attendees:activeBooked.map(b=>({bookingId:b.id,clientId:b.client_id,name:people[b.client_id]||'Socio',status:b.status})),
   blocked,
   startsAt:o.starts_at,
   endsAt:o.ends_at,
   clientBooked:Boolean(clientBooking&&['booked','attended'].includes(clientBooking.status)),
   clientWaitlist:clientBooking?.status==='waitlist',
   clientBookingId:clientBooking?.id||'',
   full:activeBooked.length>=Number(o.capacity||0),
   hasClassPlan:Boolean(
    meta.prescription
    && (meta.prescription.schemaVersion===1 || meta.prescription.version===1)
    && Array.isArray(meta.prescription.blocks)
    && meta.prescription.blocks.length>0
   ),
   classPlanTitle:meta.training_title||'',
   classPlanPrescription:meta.prescription||null,
   classPlanInstructions:meta.training_instructions||'',
  });
 }

function classPlanPreviewHTML(ev){
 if(!ev?.hasClassPlan||!ev.classPlanPrescription){
  return `<p class="business-empty">Esta clase aún no tiene entreno asociado.</p>`;
 }
 const visual=visualPrescription(ev.classPlanPrescription);
 const blocks=visual.blocks||[];
 const title=ev.classPlanTitle?`<strong class="pt-class-plan-preview-title">${esc(ev.classPlanTitle)}</strong>`:'';
 const notes=ev.classPlanInstructions
  ?`<p class="connected-hint">${esc(ev.classPlanInstructions)}</p>`:'';
 const list=blocks.length?blocks.map((b,i)=>{
  const n=(b.exercises||[]).length;
  const fmt=b.format&&b.format!=='none'&&b.format!=='sets'?String(b.format).toUpperCase():'';
  const moves=(b.exercises||[]).slice(0,6).map(x=>esc(x.name)).join(' · ');
  const more=n>6?` · +${n-6}`:'';
  return `<li><span class="pt-class-plan-block-idx">${i+1}</span>
   <div><strong>${esc(b.title||`Bloque ${i+1}`)}</strong>
   <small>${esc([fmt,n?`${n} mov.`:''].filter(Boolean).join(' · '))}${moves?`<br>${moves}${more}`:''}</small></div></li>`;
 }).join(''):'<li><p class="business-empty">Sin bloques.</p></li>';
 return `<div class="pt-class-plan-preview">${title}${notes}<ul class="pt-class-plan-blocks">${list}</ul></div>`;
}
 for(const s of sessions.filter(s=>s.status==='scheduled'&&s.scheduled_date===day)){
  events.push({
   sort:s.scheduled_date+'T23:59:00',kind:'entreno',
   title:s.title,subtitle:`${people[s.client_id]||'Cliente'} · sin hora fija`,
   action:'edit-session',id:s.id,source:'own',clientId:s.client_id,
   color:'#647767',location:'',attendees:[],blocked:false,
  });
 }
 for(const g of gymAssignments.filter(g=>{
  const d=new Date(g.starts_at).toLocaleDateString('sv-SE');
  return d===day&&g.status==='active';
 })){
  events.push({
   sort:g.starts_at,kind:'clase-gym',
   title:g.title,subtitle:`${timeOf(g.starts_at)} · ${esc(g.org_name||'Gimnasio')} · ${g.coach_ack==='pending'?'Pendiente de aceptar':g.coach_ack==='accepted'?'Aceptada':'—'}`,
   action:'detail-gym-assignment',id:g.id,source:'gym',ack:g.coach_ack,
   color:'#1d6fb8',location:'',attendees:[],blocked:false,
  });
 }
 return events.sort((a,b)=>String(a.sort).localeCompare(String(b.sort)));
}

export function listClassRooms(details=[]){
 const rooms=[...new Set((details||[]).map(d=>String(d.location||'').trim()).filter(Boolean))];
 return rooms.sort((a,b)=>a.localeCompare(b,'es'));
}

/**
 * @param {'home'|'client'} mode
 * clientId: filtra acciones a ese cliente (ficha).
 */
export function renderTrainerAgenda({
 clients=[],occurrences=[],bookings=[],sessions=[],gymAssignments=[],
 calendarMonth='',agendaView='month',agendaDay='',manager=false,
 mode='home',clientId='',clientName='',requestCount=0,archived=false,
 coaches=[],variant='trainer',details=[],roomFilter='',expandedOccurrenceId='',
}){
 const today=todayISO();
 const day=/^\d{4}-\d{2}-\d{2}$/.test(agendaDay)?agendaDay:today;
 const month=/^\d{4}-\d{2}$/.test(calendarMonth)?calendarMonth:day.slice(0,7);
 const [y,m]=month.split('-').map(Number);
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const first=(new Date(y,m-1,1).getDay()+6)%7;
 const nDays=new Date(y,m,0).getDate();
 const isClient=mode==='client';
 const isGym=variant==='gym';
 const canEdit=manager&&!archived;
 const rooms=isGym?listClassRooms(details):[];
 const room=String(roomFilter||'');
 const dayOpts={
  day,clients,occurrences,bookings,sessions,gymAssignments,coaches,
  details,roomFilter:room,includeCancelled:isGym,focusClientId:isClient?clientId:'',
 };
 const marks=new Set();
 occurrences.filter(o=>['active',...(isGym?['cancelled']:[])].includes(o.status)).forEach(o=>{
  const meta=(details||[]).find(d=>d.occurrence_id===o.id);
  if(room&&String(meta?.location||'').trim().toLowerCase()!==room.toLowerCase())return;
  marks.add(new Date(o.starts_at).toLocaleDateString('sv-SE'));
 });
 sessions.filter(s=>s.status==='scheduled').forEach(s=>marks.add(s.scheduled_date));
 gymAssignments.filter(g=>g.status==='active').forEach(g=>marks.add(new Date(g.starts_at).toLocaleDateString('sv-SE')));

 // Gym: sin título/fecha ni acciones (van al header). PT conserva toolbar.
 const toolbar=isClient||isGym?'':`<div class="pt-home-toolbar">
   <div><span class="connected-eyebrow">${esc(new Date().toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'}))}</span>
   <h1 class="pt-home-title">Agenda</h1></div>
   <div class="pt-home-actions">
    ${manager?`<button type="button" class="connected-secondary" data-action="open-invite-modal">Invitar</button>`:''}
    ${manager?`<button type="button" class="connected-secondary pt-requests-btn" data-action="open-notifications">Notificaciones${requestCount>0?`<span class="pt-badge" aria-label="${requestCount} pendientes">${requestCount>99?'99+':requestCount}</span>`:''}</button>`:''}
   </div></div>`;
 const dayTools=canEdit?`<div class="pt-day-tools">
  ${isGym
    ?(isClient
      ?`<button type="button" class="connected-primary" data-action="open-quick-workout" data-id="${esc(clientId)}" data-day="${esc(day)}">Crear entrenamiento</button>`
      :`<button type="button" class="connected-primary" data-action="open-new-class-modal" data-day="${esc(day)}">Nueva clase</button>
        <button type="button" class="connected-secondary" data-action="assign-day-class-training" data-day="${esc(day)}">Asignar entreno del día</button>`)
    :`<button type="button" class="connected-primary" data-action="open-quick-workout" data-id="${esc(clientId)}" data-day="${esc(day)}">${isClient?'Crear entrenamiento':'Asignar entrenamiento'}</button>
      ${!isClient?`<button type="button" class="connected-secondary" data-action="quick-plan-day" data-day="${esc(day)}">Planificar día</button>`:''}`}
 </div>`:'';

 const gymRoomFilter=isGym&&rooms.length>1
  ?`<label class="pt-room-filter"><span class="sr-only">Sala</span>
     <select data-action="agenda-room-filter" aria-label="Filtrar por sala">
      <option value="">Todas las salas</option>
      ${rooms.map(r=>`<option value="${esc(r)}" ${r===room?'selected':''}>${esc(r)}</option>`).join('')}
     </select></label>`
  :'';
 const viewToggle=isGym
  ?`<div class="pt-agenda-bar">
   <div class="pt-agenda-bar-lead">${gymRoomFilter||'<span class="pt-agenda-bar-spacer" aria-hidden="true"></span>'}</div>
   <div class="pt-agenda-nav">
    ${buttonNav('‹','calendar-prev')}<button type="button" class="pt-month-label" data-action="calendar-today">${esc(title)}</button>${buttonNav('›','calendar-next')}
   </div>
  </div>`
  :`<div class="pt-agenda-bar">
  <div class="pt-view-toggle" role="tablist" aria-label="Vista de agenda">
   <button type="button" role="tab" data-action="agenda-view" data-agenda-view="month" aria-selected="${agendaView==='month'}">Mes</button>
   <button type="button" role="tab" data-action="agenda-view" data-agenda-view="day" aria-selected="${agendaView==='day'}">Día</button>
  </div>
  <div class="pt-agenda-nav">
   ${agendaView==='month'
     ?`${buttonNav('‹','calendar-prev')}<button type="button" class="pt-month-label" data-action="calendar-today">${esc(title)}</button>${buttonNav('›','calendar-next')}`
     :`${buttonNav('‹','agenda-day-prev')}<button type="button" class="pt-month-label" data-action="agenda-day-today">${esc(dayLabel(day))}</button>${buttonNav('›','agenda-day-next')}`}
  </div>
 </div>`;

 const useMonth=isGym||agendaView==='month';
 let body='';
 if(useMonth){
  const cells=Array.from({length:first+nDays},(_,i)=>{
   const d=i-first+1;if(d<1)return '<span class="business-calendar-empty" aria-hidden="true"></span>';
   const iso=month+'-'+String(d).padStart(2,'0');
   const all=collectDayEvents({...dayOpts,day:iso});
   const dayEvents=all.slice(0,3);
   const more=all.length-dayEvents.length;
   const addAction=isGym?'open-new-class-modal':'new-date-appointment';
   return `<div class="business-calendar-cell pt-cal-cell ${iso===today?'is-today':''} ${iso===day?'is-selected':''}">
    <div class="pt-cal-day-row">
     <button type="button" class="business-calendar-day" data-action="agenda-select-day" data-day="${iso}" aria-label="Ver ${d} de ${esc(title)} en el detalle" aria-pressed="${iso===day?'true':'false'}">${d}${marks.has(iso)?'<span class="pt-dot" aria-hidden="true"></span>':''}</button>
     ${canEdit?`<button type="button" class="pt-cal-add" data-action="${addAction}" data-day="${iso}" ${clientId?`data-client="${esc(clientId)}"`:''} aria-label="Añadir el día ${d}">+</button>`:''}
    </div>
    ${dayEvents.map(ev=>isGym
      ?`<button type="button" class="business-calendar-event pt-cal-class ${ev.blocked?'is-blocked':''}" style="--class-color:${esc(ev.color||'#22834d')}" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}">
         <span class="pt-cal-swatch" aria-hidden="true"></span>
         <span class="pt-cal-class-text"><strong>${esc(ev.title)}</strong>${ev.coachLabel?`<small>${esc(ev.coachLabel)}</small>`:''}</span>
       </button>`
      :`<button type="button" class="business-calendar-event pt-ev-${esc(ev.kind)}" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}"><span>${esc(ev.kind)}</span> ${esc(ev.title)}</button>`
    ).join('')}
    ${more>0?`<button type="button" class="pt-more-day" data-action="agenda-select-day" data-day="${iso}">+${more}</button>`:''}
   </div>`;
  }).join('');
  body=`<div class="pt-month-layout">
   <div class="pt-month-cal">
    <div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div>
    <div class="business-calendar-grid pt-cal-grid">${cells}</div>
   </div>
   <section class="pt-day-rail" aria-label="Detalle del día">
    <div class="business-panel-head"><div><h2>${esc(dayLabel(day))}</h2>
     <p>${isClient?'Citas y entrenos.':isGym?'Clases del día.':'Citas, entrenos y clases.'}</p></div>
     ${dayTools}
    </div>
    ${renderDayList(collectDayEvents(dayOpts),{canEdit,day,clientId,isGym,isClient,expandedOccurrenceId})}
   </section>
  </div>`;
 }else{
  const dayEvents=collectDayEvents(dayOpts);
  body=`<section class="pt-day-full" data-agenda-panel="day">
   <header class="pt-day-full-head">
    <div>
     <span class="connected-eyebrow">${esc(day===today?'Hoy':dayLabel(day))}</span>
     <h2>${dayEvents.length?`${dayEvents.length} en la agenda`:'Día libre'}</h2>
    </div>
    ${dayTools}
   </header>
   ${renderDayList(dayEvents,{canEdit,day,clientId,isGym,isClient,expandedOccurrenceId})}
  </section>`;
}

 const pendingGym=!isClient?gymAssignments.filter(g=>g.coach_ack==='pending'&&g.status==='active'&&new Date(g.starts_at)>=new Date()):[];
 const gymBlock=pendingGym.length?`<section class="connected-card pt-gym-inbox">
  <div class="business-panel-head"><div><h2>Clases del gimnasio</h2>
   <p>Te han asignado estas clases. Acéptalas para verlas en tu agenda.</p></div></div>
  <div class="pt-gym-list">${pendingGym.map(g=>`<article class="pt-gym-row">
   <div><strong>${esc(g.title)}</strong><small>${dateTime(g.starts_at)} · ${esc(g.org_name||'Centro')}</small></div>
   <div class="pt-gym-actions">
    <button type="button" class="connected-primary" data-action="coach-ack" data-id="${esc(g.id)}" data-ack="accepted">Aceptar</button>
    <button type="button" class="connected-secondary" data-action="coach-ack" data-id="${esc(g.id)}" data-ack="declined">Rechazar</button>
   </div></article>`).join('')}</div></section>`:'';

 return `${toolbar}${viewToggle}<div class="pt-agenda-shell connected-card">${body}</div>${gymBlock}`;
}

function buttonNav(label,action){
 return `<button type="button" class="connected-secondary pt-nav-btn" data-action="${action}" aria-label="${label}">${label}</button>`;
}

function renderDayList(events,{canEdit=false,day='',clientId='',isGym=false,isClient=false,expandedOccurrenceId=''}={}){
 if(!events.length){
  return `<div class="pt-day-empty"><p class="business-empty">Nada programado este día.</p></div>`;
 }
 if(isGym){
  return `<div class="pt-day-events pt-gym-day-events">${events.map(ev=>{
   const open=expandedOccurrenceId===ev.id;
   const metaBits=[
    timeOf(ev.startsAt)+(ev.endsAt?`–${timeOf(ev.endsAt)}`:''),
    ev.coachLabel?`Entrenador: ${ev.coachLabel}`:'',
    ev.location?`Sala: ${ev.location}`:'',
    ev.blocked?'Bloqueada · no admite inscripciones':`${ev.bookedCount||0}/${ev.capacity||0} plazas`,
    isClient&&ev.clientBooked?'Apuntado':'',
    isClient&&ev.clientWaitlist?'Lista de espera':'',
   ].filter(Boolean);
   const clientEnroll=isClient&&clientId&&canEdit&&!ev.blocked&&!ev.clientBooked&&!ev.clientWaitlist
    ?`<button type="button" class="connected-primary ${ev.full?'is-muted':''}" data-action="enroll-client-in-class" data-id="${esc(ev.id)}" data-client="${esc(clientId)}" ${ev.full?'disabled':''}>${ev.full?'Completa':'Apuntar'}</button>`
    :'';
   const clientCancel=isClient&&clientId&&canEdit&&(ev.clientBooked||ev.clientWaitlist)&&ev.clientBookingId
    ?`<button type="button" class="connected-secondary" data-action="remove-booking" data-id="${esc(ev.clientBookingId)}">Cancelar</button>`
    :'';
   const detailBtn=`<button type="button" class="connected-secondary pt-class-detail-btn" data-action="toggle-occurrence-detail" data-id="${esc(ev.id)}" aria-expanded="${open?'true':'false'}">${open?'Ocultar':'Detalle'}</button>`;
   const staffLeft=!isClient
    ?`${canEdit?`<button type="button" class="connected-secondary" data-action="open-edit-class-modal" data-id="${esc(ev.id)}">Editar clase</button>`:''}
      ${canEdit&&!ev.blocked?`<button type="button" class="connected-secondary" data-action="publish-class-plan" data-id="${esc(ev.id)}">${ev.hasClassPlan?'Editar entreno':'Añadir entreno'}</button>`:''}
      ${canEdit&&!ev.blocked&&ev.hasClassPlan?`<button type="button" class="connected-secondary pt-danger-btn" data-action="clear-class-plan" data-id="${esc(ev.id)}">Quitar entreno</button>`:''}`
    :'';
   return `<article class="pt-event-card pt-gym-class-card ${ev.blocked?'is-blocked':''} ${open?'is-open':''} ${ev.clientBooked?'is-client-booked':''} ${ev.hasClassPlan?'has-class-plan':''}" style="--class-color:${esc(ev.color||'#22834d')}">
    <div class="pt-gym-class-head">
     <span class="pt-gym-class-swatch" aria-hidden="true"></span>
     <div class="pt-gym-class-title">
      <strong>${esc(ev.title)}${ev.hasClassPlan?`<span class="pt-class-plan-chip" title="${esc(ev.classPlanTitle||'Entreno asociado')}">Con entreno</span>`:`<span class="pt-class-plan-chip is-empty">Sin entreno</span>`}</strong>
      <small>${esc(metaBits.join(' · '))}</small>
     </div>
    </div>
    <div class="pt-event-actions pt-gym-class-actions">
     <div class="pt-gym-action-row pt-gym-action-row-split">
      <div class="pt-gym-action-left">${staffLeft}${clientEnroll}${clientCancel}</div>
      ${detailBtn}
     </div>
    </div>
    ${open?`<div class="pt-gym-attendees">
      ${isClient?`<h4>Qué incluye la clase</h4>${classPlanPreviewHTML(ev)}`
       :`<h4>Apuntados</h4>
      ${ev.attendees?.length
        ?`<ul>${ev.attendees.map(a=>`<li><span>${esc(a.name)}</span>${canEdit?`<button type="button" class="connected-secondary" data-action="remove-booking" data-id="${esc(a.bookingId)}">Quitar</button>`:''}</li>`).join('')}</ul>`
        :`<p class="business-empty">Nadie apuntado todavía.</p>`}
      ${canEdit&&!ev.blocked?`<div class="pt-gym-add-after">
        <button type="button" class="connected-primary" data-action="open-enroll-class" data-id="${esc(ev.id)}">Añadir</button>
        <p class="connected-hint">Inscribe a un socio manualmente; cuenta igual que si se hubiera apuntado desde la app.</p>
       </div>`:''}
      <div class="pt-gym-add-after">
        <h4>Entreno de la clase</h4>
        ${classPlanPreviewHTML(ev)}
        ${canEdit&&!ev.blocked?`<div class="pt-gym-action-row" style="margin-top:10px">
         <button type="button" class="connected-primary" data-action="publish-class-plan" data-id="${esc(ev.id)}">${ev.hasClassPlan?'Editar entreno':'Crear / asociar entreno'}</button>
         ${ev.hasClassPlan?`<button type="button" class="connected-secondary pt-danger-btn" data-action="clear-class-plan" data-id="${esc(ev.id)}">Quitar entreno</button>`:''}
        </div>`:''}
       </div>`}
     </div>`:''}
   </article>`;
  }).join('')}</div>`;
 }
 return `<div class="pt-day-events">${events.map(ev=>`<article class="pt-event-card pt-ev-${esc(ev.kind)}">
  <button type="button" class="pt-event-main" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}">
   <span class="pt-event-kind">${esc(labelKind(ev.kind,false))}</span>
   <strong>${esc(ev.title)}</strong>
   <small>${esc(ev.subtitle)}</small>
  </button>
  <div class="pt-event-actions">
   ${ev.kind==='entreno'&&canEdit?`<button type="button" class="connected-secondary" data-action="edit-session" data-id="${esc(ev.id)}">Editar</button>`:''}
   ${(ev.kind==='cita'||ev.kind==='grupo')&&canEdit?`<button type="button" class="connected-secondary" data-action="detail-occurrence" data-id="${esc(ev.id)}">Abrir</button>`:''}
   ${ev.source==='gym'&&ev.ack==='pending'?`<button type="button" class="connected-primary" data-action="coach-ack" data-id="${esc(ev.id)}" data-ack="accepted">Aceptar</button>`:''}
   ${ev.source==='gym'&&ev.ack==='accepted'&&canEdit?`<button type="button" class="connected-secondary" data-action="reschedule-occurrence" data-id="${esc(ev.id)}">Mover</button>
     <button type="button" class="connected-secondary" data-action="cancel-occurrence" data-id="${esc(ev.id)}">Cancelar</button>`:''}
  </div>
 </article>`).join('')}</div>`;
}

function labelKind(k){
 return ({cita:'Cita',grupo:'Grupo',entreno:'Entreno','clase-gym':'Clase centro'})[k]||k;
}

export function renderGymAssignmentDialog(assignment){
 if(!assignment)return '';
 const pending=assignment.coach_ack==='pending';
 const accepted=assignment.coach_ack==='accepted';
 const future=new Date(assignment.starts_at)>new Date();
 const startLocal=new Date(assignment.starts_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16);
 const endLocal=new Date(assignment.ends_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16);
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-gym-dialog" role="dialog" aria-modal="true" aria-label="Clase del gimnasio">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Clase del centro</span><h2>${esc(assignment.title)}</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <p class="connected-hint">${esc(assignment.org_name||'Gimnasio')} · ${dateTime(assignment.starts_at)} – ${timeOf(assignment.ends_at)}
    · ${pending?'Pendiente de aceptar':accepted?'Aceptada':'—'}</p>
   ${pending?`<div class="pt-gym-actions">
     <button type="button" class="connected-primary" data-action="coach-ack" data-id="${esc(assignment.id)}" data-ack="accepted">Aceptar clase</button>
     <button type="button" class="connected-secondary" data-action="coach-ack" data-id="${esc(assignment.id)}" data-ack="declined">Rechazar</button>
    </div>`:''}
   ${accepted&&future?`<form data-connected="coach-reschedule" class="business-form">
     <input type="hidden" name="id" value="${esc(assignment.id)}">
     <label class="connected-field">Nuevo inicio<input name="start" type="datetime-local" value="${esc(startLocal)}" required></label>
     <label class="connected-field">Nuevo fin<input name="end" type="datetime-local" value="${esc(endLocal)}" required></label>
     <button type="submit" class="connected-primary">Mover clase</button>
    </form>
    <button type="button" class="connected-secondary" data-action="coach-cancel-occurrence" data-id="${esc(assignment.id)}">Cancelar clase y devolver créditos</button>`:''}
   ${!future?'<p class="business-empty">Esta clase ya ha empezado o terminó.</p>':''}
  </div>
 </section></div>`;
}

export function renderInviteModal({
 gym=false,draft=null,emailError='',offers=[],busy=false,trainer=false,
}={}){
 const who=gym?'socio':'cliente';
 const d=draft&&typeof draft==='object'?draft:{};
 const name=d.name||'';
 const email=d.email||'';
 const phone=d.phone||'';
 const mode=d.passMode||'none';
 const trialCredits=d.trialCredits||'3';
 const trialDays=d.trialDays||'30';
 const offerId=d.offerId||'';
 const paymentMethod=d.paymentMethod||'cash';
 const paidAmount=d.paidAmount||'';
 const paymentNote=d.paymentNote||'';
 const err=String(emailError||'').trim();
 const activeOffers=(offers||[]).filter(o=>o.is_active);
 const kindDefault=trainer?'appointment':'class';
 const offerOpts=activeOffers.map(o=>`<option value="${esc(o.id)}" ${o.id===offerId?'selected':''}>${esc(o.name)} · ${o.credits>=9000?'Ilimitado':o.credits+' ses.'} · ${((o.price_cents||0)/100).toFixed(2)} €</option>`).join('');
 return `<div class="business-overlay pt-overlay" data-invite-overlay><section class="business-dialog pt-sheet pt-invite-dialog" role="dialog" aria-modal="true" aria-label="Invitar ${who}">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">${gym?'Socios':'Clientes'}</span><h2>Invitar ${who}</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-invite-modal" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <form data-connected="client" class="business-form pt-sheet-form" id="invite-client-form" novalidate data-invite-pass-form>
    <div class="pt-sheet-hero"><p>Crea la ficha y, si quieres, deja ya el acceso (prueba o bono cobrado). El enlace abre la app en Ajustes para que acepte el centro.</p></div>
    <label class="connected-field">Nombre<input name="name" type="text" required minlength="2" maxlength="120" autocomplete="name" value="${esc(name)}"></label>
    <label class="connected-field${err?' is-invalid':''}">Correo
     <input name="email" type="email" required autocomplete="email" value="${esc(email)}" aria-invalid="${err?'true':'false'}" ${err?'aria-describedby="invite-email-error"':''}>
     ${err?`<p id="invite-email-error" class="connected-field-error" role="alert">${esc(err)}</p>`:''}
    </label>
    <label class="connected-field">Móvil (para WhatsApp)<input name="phone" type="tel" inputmode="tel" autocomplete="tel" maxlength="20" placeholder="+34 600 000 000" value="${esc(phone)}"></label>
    <fieldset class="pt-invite-pass-mode">
     <legend>Acceso al invitar</legend>
     <label class="pt-invite-radio"><input type="radio" name="passMode" value="none" ${mode==='none'?'checked':''} data-invite-pass-mode><span>Solo invitar (elige bono después)</span></label>
     <label class="pt-invite-radio"><input type="radio" name="passMode" value="trial" ${mode==='trial'?'checked':''} data-invite-pass-mode><span>Sesiones de prueba</span></label>
     <label class="pt-invite-radio"><input type="radio" name="passMode" value="paid" ${mode==='paid'?'checked':''} data-invite-pass-mode><span>Bono cobrado ahora</span></label>
    </fieldset>
    <div data-invite-pass-panel="trial" ${mode==='trial'?'':'hidden'}>
     <div class="trainer-form-cols">
      <label class="connected-field">Sesiones de prueba<input name="trialCredits" type="number" min="1" max="100" value="${esc(trialCredits)}"></label>
      <label class="connected-field">Válidas (días)<input name="trialDays" type="number" min="1" max="365" value="${esc(trialDays)}"></label>
      <label class="connected-field">Tipo<select name="trialKind">
       <option value="class" ${kindDefault==='class'?'selected':''}>Clases</option>
       <option value="appointment" ${kindDefault==='appointment'?'selected':''}>Citas 1:1</option>
      </select></label>
     </div>
     <p class="connected-hint">Cortesía sin cobro en Repera. Después podrás asignarle un plan de pago.</p>
    </div>
    <div data-invite-pass-panel="paid" ${mode==='paid'?'':'hidden'}>
     ${offerOpts?`<label class="connected-field">Tarifa / bono<select name="offer">${offerOpts}</select></label>
     <div class="trainer-form-cols">
      <label class="connected-field">Forma de pago<select name="paymentMethod">
       <option value="cash" ${paymentMethod==='cash'?'selected':''}>Efectivo</option>
       <option value="transfer" ${paymentMethod==='transfer'?'selected':''}>Transferencia</option>
       <option value="card" ${paymentMethod==='card'?'selected':''}>Tarjeta</option>
       <option value="other" ${paymentMethod==='other'?'selected':''}>Otro</option>
      </select></label>
      <label class="connected-field">Importe (€)<input name="paidAmount" type="number" min="0" max="100000" step=".01" value="${esc(paidAmount)}" placeholder="Precio de la tarifa"></label>
     </div>
     <label class="connected-field">Nota del cobro (opcional)<input name="paymentNote" maxlength="400" value="${esc(paymentNote)}" placeholder="Bizum, recibo…"></label>
     <label class="trainer-verify"><input name="confirmed" value="yes" type="checkbox" ${mode==='paid'?'required':''}>
      Confirmo que he cobrado fuera de Repera. No genera factura en la plataforma.</label>`
      :'<p class="connected-hint">No hay planes activos. Crea uno en Planes o elige sesiones de prueba.</p>'}
    </div>
    <button type="submit" class="connected-primary" ${busy?'disabled':''}>Crear e invitar</button>
   </form>
  </div>
 </section></div>`;
}

function enrollmentRows(waiting=[]){
 return waiting.map(r=>`<article class="business-enrollment-row">
  <div class="business-enrollment-avatar">${/^https:\/\//.test(r.avatar_url||'')?`<img src="${esc(r.avatar_url)}" alt="" loading="lazy">`:esc((r.name||'?').slice(0,1).toUpperCase())}</div>
  <div class="business-enrollment-text"><strong>${esc(r.name||'Atleta')}</strong>
   <small>${esc(r.email||'—')} · ${r.pass_kind==='appointment'?'Entrenamiento personal':'Clases'}</small>
   ${r.note?`<p>${esc(r.note)}</p>`:''}</div>
  <div class="business-enrollment-actions">
   <button type="button" class="connected-primary" data-action="approve-enrollment" data-id="${esc(r.id)}">Aceptar</button>
   <button type="button" class="connected-secondary" data-action="reject-enrollment" data-id="${esc(r.id)}">Rechazar</button>
  </div></article>`).join('');
}

/** @deprecated Usar renderNotificationsDrawer */
export function renderRequestsModal({waiting=[],manager=false}){
 return renderNotificationsDrawer({waiting,manager,clients:[],occurrences:[],groups:[],busy:false,focus:'requests'});
}

/** @deprecated Usar renderNotificationsDrawer */
export function renderBroadcastModal(opts={}){
 return renderNotificationsDrawer({...opts,focus:'broadcast'});
}

/** Panel lateral Notificaciones: solicitudes + envío de avisos. */
export function renderNotificationsDrawer({
 waiting=[],clients=[],occurrences=[],groups=[],manager=false,busy=false,focus='requests',
}={}){
 const active=clients.filter(c=>c.status==='active'&&c.user_id&&!c.account_deleted_at);
 const upcoming=occurrences.filter(o=>o.status==='active').slice(0,40);
 const when=t=>t?new Date(t).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}):'';
 const peopleLabel=active.some(()=>true)?'clientes / socios':'personas';
 return `<div class="business-overlay pt-overlay pt-notif-overlay" data-action="close-business-dialog">
  <aside class="pt-notif-drawer" role="dialog" aria-modal="true" aria-label="Notificaciones" onclick="event.stopPropagation()">
   <div class="pt-notif-head">
    <div><span class="pt-sheet-kicker">Bandeja</span><h2>Notificaciones</h2></div>
    <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button>
   </div>
   <div class="pt-notif-scroll">
    <section class="pt-notif-section" data-notif-focus="${focus==='requests'?'on':''}">
     <div class="pt-notif-section-head">
      <h3>Solicitudes${waiting.length?` · ${waiting.length}`:''}</h3>
      ${manager?`<button type="button" class="connected-secondary" data-action="refresh-enrollments">Actualizar</button>`:''}
     </div>
     ${!manager?'<p class="connected-hint">No tienes permiso para gestionar solicitudes.</p>':
       waiting.length?`<div class="business-inbox-list">${enrollmentRows(waiting)}</div>`:
       '<div class="pt-sheet-empty"><p>Nadie pendiente. Cuando pidan vincularse desde la app, saldrán aquí.</p></div>'}
    </section>
    ${manager?`<section class="pt-notif-section" data-notif-focus="${focus==='broadcast'?'on':''}">
     <div class="pt-notif-section-head"><h3>Enviar aviso</h3></div>
     <form data-connected="chat-broadcast" class="business-form pt-sheet-form">
      <p class="connected-hint">Llega a la app de tus ${esc(peopleLabel)}. No es un email.</p>
      <label class="connected-field">Destinatarios
       <select name="scope" required>
        <option value="all">Todos los activos vinculados</option>
        <option value="occurrence">Inscritos de una clase</option>
        <option value="group">Miembros de un grupo</option>
        <option value="selected">Selección manual</option>
       </select>
      </label>
      <label class="connected-field">Clase<select name="occurrence">
       <option value="">—</option>
       ${upcoming.map(o=>`<option value="${esc(o.id)}">${esc(o.title)} · ${esc(when(o.starts_at))}</option>`).join('')}
      </select></label>
      <label class="connected-field">Grupo<select name="group">
       <option value="">—</option>
       ${groups.map(g=>`<option value="${esc(g.id)}">${esc(g.name)}</option>`).join('')}
      </select></label>
      <fieldset class="business-broadcast-pick"><legend>Selección manual</legend>
       <div class="business-group-members">${active.map(c=>`<label><input type="checkbox" name="clients" value="${esc(c.id)}"><span>${esc(c.name)}</span></label>`).join('')||'<p>Sin vinculados.</p>'}
      </div></fieldset>
      <label class="connected-field">Mensaje<textarea name="body" rows="3" maxlength="2000" required placeholder="Recordatorio de horario, aviso de cierre…"></textarea></label>
      <button type="submit" class="connected-primary" ${busy?'disabled':''}>Enviar aviso</button>
     </form>
    </section>`:''}
   </div>
  </aside>
 </div>`;
}

export function renderQuickWorkoutModal({clients=[],day='',clientId=''}){
 const start=day||todayISO();
 const options=clients.filter(c=>c.status==='active'&&!c.account_deleted_at)
  .map(c=>`<option value="${esc(c.id)}" ${c.id===clientId?'selected':''}>${esc(c.name)}</option>`).join('');
 const dow=[['1','L'],['2','M'],['3','X'],['4','J'],['5','V'],['6','S'],['7','D']];
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-workout-dialog" role="dialog" aria-modal="true" aria-label="Añadir entreno">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Plan</span><h2>Añadir entreno</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <form data-connected="quick-workout" class="business-form pt-sheet-form pt-quick-workout">
    <div class="pt-sheet-hero"><p>Diseña el estímulo y elige si es un día, varios días a la semana o un plan completo.</p></div>
    <label class="connected-field">Cliente<select name="client" required>${options||'<option value="">Sin clientes</option>'}</select></label>
    <label class="connected-field">Título<input name="title" type="text" maxlength="120" placeholder="Fuerza · tren inferior" required></label>

    <fieldset class="pt-plan-scope"><legend>Cuándo</legend>
     <div class="pt-scope-cards" role="radiogroup" aria-label="Alcance del plan">
      <label class="pt-scope-card"><input type="radio" name="mode" value="day" checked data-quick-mode>
       <span><strong>Un día</strong><small>Solo la fecha elegida</small></span></label>
      <label class="pt-scope-card"><input type="radio" name="mode" value="weekly" data-quick-mode>
       <span><strong>Semanal</strong><small>Repite los días que marques</small></span></label>
      <label class="pt-scope-card"><input type="radio" name="mode" value="plan" data-quick-mode>
       <span><strong>Plan completo</strong><small>Rango con días de entreno</small></span></label>
     </div>
     <div class="pt-plan-dates">
      <label class="connected-field">Desde<input name="date" type="date" value="${esc(start)}" required></label>
      <label class="connected-field" data-quick-end hidden>Hasta<input name="end" type="date" value="${esc(start)}"></label>
      <label class="connected-field" data-quick-weeks hidden>Semanas<input name="weeks" type="number" min="1" max="8" value="4"></label>
     </div>
     <div class="pt-weekday-picks" data-quick-weekdays hidden>
      <span class="pt-weekday-label">Días de entreno</span>
      <div class="pt-weekday-chips">${dow.map(([v,l],i)=>`
       <label class="pt-weekday-chip"><input type="checkbox" name="weekdays" value="${v}" ${i<5?'checked':''}><span>${l}</span></label>`).join('')}
      </div>
     </div>
     <p class="connected-hint" data-quick-preview>1 sesión el ${esc(start)}</p>
    </fieldset>

    <fieldset class="pt-quick-block"><legend>Movimientos</legend>
     <div class="pt-format-pills" role="group" aria-label="Formato">
      ${[['sets','Series'],['amrap','AMRAP'],['emom','EMOM'],['rft','RFT'],['fortime','For Time']].map(([v,l],i)=>`
       <label class="pt-format-pill"><input type="radio" name="format" value="${v}" ${i===0?'checked':''}><span>${l}</span></label>`).join('')}
     </div>
     <div class="pt-quick-defaults">
      <span class="pt-weekday-label">Valores al añadir</span>
      <div class="pt-quick-nums">
       <label class="connected-field">Series<input name="sets" type="number" min="1" max="50" value="3"></label>
       <label class="connected-field">Reps<input name="reps" type="number" min="0" max="1000" value="8"></label>
       <label class="connected-field">Kg<input name="weight" type="number" min="0" max="1000" step="0.5" value="0"></label>
       <label class="connected-field">RIR<input name="rir" type="number" min="0" max="10" value="2"></label>
      </div>
     </div>
     <div class="pt-session-board" data-quick-movements aria-live="polite">
      <p class="pt-session-empty">Toca un ejercicio de la biblioteca para armar la sesión.</p>
     </div>
     <div class="pt-ex-library">
      <label class="connected-field">Biblioteca (como en la app)
       <input type="search" data-quick-search placeholder="Sentadilla, burpee, press…" autocomplete="off">
      </label>
      <div class="pt-ex-grid" data-quick-picker>
       ${MOVEMENTS.map(m=>`<button type="button" class="pt-ex-tile" data-action="quick-pick-exercise" data-id="${esc(m.id)}" data-name="${esc(m.name)}" data-art="${esc(m.art||'')}" data-search="${esc((m.name+' '+m.group+' '+m.id).toLowerCase())}">
        ${exerciseThumbHTML(m,{size:'exercise-thumb-lg'})}
        <span><strong>${esc(m.name)}</strong><small>${esc(m.group)}</small></span>
       </button>`).join('')}
      </div>
     </div>
    </fieldset>
    <label class="connected-field">Notas<textarea name="instructions" rows="2" maxlength="2000" placeholder="Tempo, descanso…"></textarea></label>
    <button type="submit" class="connected-primary" ${options?'':'disabled'}>Programar</button>
   </form>
  </div>
 </section></div>`;
}

/** Cuenta sesiones previstas para el preview del modal rápido. */
export function countQuickWorkoutSessions({mode,start,end,weeks,weekdays}){
 if(!/^\d{4}-\d{2}-\d{2}$/.test(start||''))return 0;
 if(mode==='day')return 1;
 const days=(Array.isArray(weekdays)?weekdays:[]).map(Number).filter(n=>n>=1&&n<=7);
 if(!days.length)return 0;
 let to=end;
 if(mode==='weekly'){
  const n=Math.min(Math.max(Number(weeks)||1,1),8);
  const d=new Date(start+'T12:00:00');d.setDate(d.getDate()+(n*7)-1);
  to=d.toLocaleDateString('sv-SE');
 }
 if(!/^\d{4}-\d{2}-\d{2}$/.test(to||'')||to<start)return 0;
 let count=0;
 for(let cur=new Date(start+'T12:00:00'),last=new Date(to+'T12:00:00');cur<=last;cur.setDate(cur.getDate()+1)){
  const iso=cur.getDay()||7; // 1=lun … 7=dom
  if(days.includes(iso))count++;
 }
 return count;
}
