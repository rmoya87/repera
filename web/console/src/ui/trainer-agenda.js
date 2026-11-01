// Agenda PT: vista mes / día, citas + entrenos, clases de gym asignadas.
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const dayLabel=iso=>new Date(iso+'T12:00:00').toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'});
const timeOf=iso=>iso?new Date(iso).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}):'';
const dateTime=iso=>iso?new Date(iso).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}):'—';

export function todayISO(){return new Date().toLocaleDateString('sv-SE');}

export function collectDayEvents({day,clients=[],occurrences=[],bookings=[],sessions=[],gymAssignments=[]}){
 const people=Object.fromEntries(clients.map(c=>[c.id,c.name]));
 const events=[];
 for(const o of occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at).toLocaleDateString('sv-SE')===day)){
  const n=bookings.filter(b=>b.occurrence_id===o.id&&['booked','attended'].includes(b.status)).length;
  events.push({
   sort:o.starts_at,kind:o.kind==='appointment'?'cita':'grupo',
   title:o.title,subtitle:`${timeOf(o.starts_at)} · ${n} reserva${n===1?'':'s'}`,
   action:'detail-occurrence',id:o.id,source:'own',
  });
 }
 for(const s of sessions.filter(s=>s.status==='scheduled'&&s.scheduled_date===day)){
  events.push({
   sort:s.scheduled_date+'T23:59:00',kind:'entreno',
   title:s.title,subtitle:`${people[s.client_id]||'Cliente'} · sin hora fija`,
   action:'edit-session',id:s.id,source:'own',clientId:s.client_id,
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
  });
 }
 return events.sort((a,b)=>String(a.sort).localeCompare(String(b.sort)));
}

export function renderTrainerAgenda({
 clients=[],occurrences=[],bookings=[],sessions=[],gymAssignments=[],
 calendarMonth='',agendaView='month',agendaDay='',manager=false,inboxHtml='',
}){
 const today=todayISO();
 const day=/^\d{4}-\d{2}-\d{2}$/.test(agendaDay)?agendaDay:today;
 const month=/^\d{4}-\d{2}$/.test(calendarMonth)?calendarMonth:day.slice(0,7);
 const [y,m]=month.split('-').map(Number);
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const first=(new Date(y,m-1,1).getDay()+6)%7;
 const nDays=new Date(y,m,0).getDate();
 const marks=new Set();
 occurrences.filter(o=>o.status==='active').forEach(o=>marks.add(new Date(o.starts_at).toLocaleDateString('sv-SE')));
 sessions.filter(s=>s.status==='scheduled').forEach(s=>marks.add(s.scheduled_date));
 gymAssignments.filter(g=>g.status==='active').forEach(g=>marks.add(new Date(g.starts_at).toLocaleDateString('sv-SE')));

 const toolbar=`<div class="pt-home-toolbar">
  <div><span class="connected-eyebrow">${esc(new Date().toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long'}))}</span>
  <h1 class="pt-home-title">Agenda</h1></div>
  <div class="pt-home-actions">
   ${manager?`<button type="button" class="connected-primary" data-action="new-date-appointment" data-day="${esc(day)}">Crear cita</button>`:''}
   ${manager?`<button type="button" class="connected-secondary" data-action="open-invite-modal">Invitar cliente</button>`:''}
  </div></div>`;

 const viewToggle=`<div class="pt-agenda-bar">
  <div class="pt-view-toggle" role="tablist" aria-label="Vista de agenda">
   <button type="button" role="tab" data-action="agenda-view" data-view="month" aria-selected="${agendaView==='month'}">Mes</button>
   <button type="button" role="tab" data-action="agenda-view" data-view="day" aria-selected="${agendaView==='day'}">Día</button>
  </div>
  <div class="pt-agenda-nav">
   ${agendaView==='month'
     ?`${buttonNav('‹','calendar-prev')}<button type="button" class="pt-month-label" data-action="calendar-today">${esc(title)}</button>${buttonNav('›','calendar-next')}`
     :`${buttonNav('‹','agenda-day-prev')}<button type="button" class="pt-month-label" data-action="agenda-day-today">${esc(dayLabel(day))}</button>${buttonNav('›','agenda-day-next')}`}
  </div>
 </div>`;

 let body='';
 if(agendaView==='month'){
  const cells=Array.from({length:first+nDays},(_,i)=>{
   const d=i-first+1;if(d<1)return '<span class="business-calendar-empty" aria-hidden="true"></span>';
   const iso=month+'-'+String(d).padStart(2,'0');
   const dayEvents=collectDayEvents({day:iso,clients,occurrences,bookings,sessions,gymAssignments}).slice(0,3);
   const more=collectDayEvents({day:iso,clients,occurrences,bookings,sessions,gymAssignments}).length-dayEvents.length;
   return `<div class="business-calendar-cell pt-cal-cell ${iso===today?'is-today':''} ${iso===day?'is-selected':''}">
    <button type="button" class="business-calendar-day" data-action="agenda-select-day" data-day="${iso}" aria-label="${d}">${d}${marks.has(iso)?'<span class="pt-dot" aria-hidden="true"></span>':''}</button>
    ${dayEvents.map(ev=>`<button type="button" class="business-calendar-event pt-ev-${esc(ev.kind)}" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}"><span>${esc(ev.kind)}</span> ${esc(ev.title)}</button>`).join('')}
    ${more>0?`<button type="button" class="pt-more-day" data-action="agenda-select-day" data-day="${iso}">+${more}</button>`:''}
   </div>`;
  }).join('');
  body=`<div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div>
   <div class="business-calendar-grid pt-cal-grid">${cells}</div>
   <section class="pt-day-rail" aria-label="Detalle del día">
    <div class="business-panel-head"><div><h2>${esc(dayLabel(day))}</h2>
     <p>Citas, entrenos y clases del centro.</p></div>
     ${manager?`<button type="button" class="connected-secondary" data-action="new-date-appointment" data-day="${esc(day)}">Nueva cita</button>`:''}
    </div>
    ${renderDayList(collectDayEvents({day,clients,occurrences,bookings,sessions,gymAssignments}),manager)}
   </section>`;
 }else{
  body=`<section class="pt-day-full">
   ${manager?`<div class="pt-day-tools"><button type="button" class="connected-primary" data-action="new-date-appointment" data-day="${esc(day)}">Nueva cita este día</button>
    <button type="button" class="connected-secondary" data-action="quick-plan-day" data-day="${esc(day)}">Asignar entreno</button></div>`:''}
   ${renderDayList(collectDayEvents({day,clients,occurrences,bookings,sessions,gymAssignments}),manager)}
  </section>`;
 }

 const pendingGym=gymAssignments.filter(g=>g.coach_ack==='pending'&&g.status==='active'&&new Date(g.starts_at)>=new Date());
 const gymBlock=pendingGym.length?`<section class="connected-card pt-gym-inbox">
  <div class="business-panel-head"><div><h2>Clases del gimnasio</h2>
   <p>Te han asignado estas clases. Acéptalas para verlas en tu agenda.</p></div></div>
  <div class="pt-gym-list">${pendingGym.map(g=>`<article class="pt-gym-row">
   <div><strong>${esc(g.title)}</strong><small>${dateTime(g.starts_at)} · ${esc(g.org_name||'Centro')}</small></div>
   <div class="pt-gym-actions">
    <button type="button" class="connected-primary" data-action="coach-ack" data-id="${esc(g.id)}" data-ack="accepted">Aceptar</button>
    <button type="button" class="connected-secondary" data-action="coach-ack" data-id="${esc(g.id)}" data-ack="declined">Rechazar</button>
   </div></article>`).join('')}</div></section>`:'';

 return `${toolbar}${viewToggle}<div class="pt-agenda-shell connected-card">${body}</div>${gymBlock}${inboxHtml}`;
}

function buttonNav(label,action){
 return `<button type="button" class="connected-secondary pt-nav-btn" data-action="${action}" aria-label="${label}">${label}</button>`;
}

function renderDayList(events,manager){
 if(!events.length)return '<p class="business-empty">Nada programado este día. Crea una cita o asigna un entreno a un cliente.</p>';
 return `<div class="pt-day-events">${events.map(ev=>`<article class="pt-event-card pt-ev-${esc(ev.kind)}">
  <button type="button" class="pt-event-main" data-action="${esc(ev.action)}" data-id="${esc(ev.id)}">
   <span class="pt-event-kind">${esc(labelKind(ev.kind))}</span>
   <strong>${esc(ev.title)}</strong>
   <small>${esc(ev.subtitle)}</small>
  </button>
  <div class="pt-event-actions">
   ${ev.kind==='entreno'&&manager?`<button type="button" class="connected-secondary" data-action="edit-session" data-id="${esc(ev.id)}">Editar</button>`:''}
   ${ev.kind==='cita'&&manager?`<button type="button" class="connected-secondary" data-action="detail-occurrence" data-id="${esc(ev.id)}">Abrir</button>`:''}
   ${ev.source==='gym'&&ev.ack==='pending'?`<button type="button" class="connected-primary" data-action="coach-ack" data-id="${esc(ev.id)}" data-ack="accepted">Aceptar</button>`:''}
   ${ev.source==='gym'&&ev.ack==='accepted'&&manager?`<button type="button" class="connected-secondary" data-action="reschedule-occurrence" data-id="${esc(ev.id)}">Mover</button>
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
 return `<div class="business-overlay"><section class="business-dialog pt-gym-dialog" role="dialog" aria-modal="true" aria-label="Clase del gimnasio">
  <div class="business-dialog-header"><h2>${esc(assignment.title)}</h2>
   <button type="button" class="icon-button" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll">
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

export function renderInviteModal(){
 return `<div class="business-overlay" data-invite-overlay><section class="business-dialog pt-invite-dialog" role="dialog" aria-modal="true" aria-label="Invitar cliente">
  <div class="business-dialog-header"><h2>Invitar cliente</h2>
   <button type="button" class="icon-button" data-action="close-invite-modal" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll">
   <form data-connected="client" class="business-form" id="invite-client-form">
    <label class="connected-field">Nombre<input name="name" type="text" required minlength="2" maxlength="120" autocomplete="name"></label>
    <label class="connected-field">Correo<input name="email" type="email" required autocomplete="email"></label>
    <p class="connected-hint">Se crea la ficha y se prepara la invitación. La vinculación se completa cuando acepte.</p>
    <button type="submit" class="connected-primary">Enviar invitación</button>
   </form>
  </div>
 </section></div>`;
}

export function renderQuickWorkoutModal({clients=[],day='',clientId=''}){
 const start=day||todayISO();
 const options=clients.filter(c=>c.status==='active'&&!c.account_deleted_at)
  .map(c=>`<option value="${esc(c.id)}" ${c.id===clientId?'selected':''}>${esc(c.name)}</option>`).join('');
 return `<div class="business-overlay"><section class="business-dialog pt-workout-dialog" role="dialog" aria-modal="true" aria-label="Añadir entreno">
  <div class="business-dialog-header"><h2>Añadir entreno</h2>
   <button type="button" class="icon-button" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll">
   <form data-connected="quick-workout" class="business-form pt-quick-workout">
    <label class="connected-field">Cliente<select name="client" required>${options||'<option value="">Sin clientes</option>'}</select></label>
    <div class="pt-schedule-mode">
     <label><input type="radio" name="mode" value="day" checked> Un día</label>
     <label><input type="radio" name="mode" value="week"> Semana (lun–vie)</label>
    </div>
    <label class="connected-field">Fecha inicio<input name="date" type="date" value="${esc(start)}" required></label>
    <label class="connected-field">Título<input name="title" type="text" maxlength="120" placeholder="Fuerza · tren inferior" required></label>
    <fieldset class="pt-quick-block"><legend>Bloque rápido</legend>
     <label class="connected-field">Formato
      <select name="format"><option value="sets">Series</option><option value="amrap">AMRAP</option>
      <option value="emom">EMOM</option><option value="rft">RFT</option><option value="fortime">For Time</option></select>
     </label>
     <label class="connected-field">Movimiento (catálogo)
      <input name="movement" list="pt-movement-list" placeholder="Buscar ejercicio…" required autocomplete="off">
      <datalist id="pt-movement-list"></datalist>
     </label>
     <div class="pt-quick-nums">
      <label class="connected-field">Series<input name="sets" type="number" min="1" max="50" value="3"></label>
      <label class="connected-field">Reps<input name="reps" type="number" min="0" max="1000" value="8"></label>
      <label class="connected-field">Kg<input name="weight" type="number" min="0" max="1000" step="0.5" value="0"></label>
      <label class="connected-field">RIR<input name="rir" type="number" min="0" max="10" value="2"></label>
     </div>
     <button type="button" class="connected-secondary" data-action="quick-add-movement">+ Añadir otro movimiento</button>
     <div data-quick-movements class="pt-quick-movements"></div>
    </fieldset>
    <label class="connected-field">Notas<textarea name="instructions" rows="2" maxlength="2000" placeholder="Tempo, descanso…"></textarea></label>
    <button type="submit" class="connected-primary" ${options?'':'disabled'}>Programar</button>
   </form>
  </div>
 </section></div>`;
}
