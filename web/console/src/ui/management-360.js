import {renderSharedAthleteSessions,renderAthleteActivity} from './athlete-activity.js';
import {renderAthleteInsights,renderAthleteGuidance} from './athlete-insights.js';
import {editorMarkup,emptyPrescription,visualPrescription} from './workout-editor.js';
// Vistas 360 de Repera Business: nunca inventan estadísticas del atleta sin consentimiento.
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const dateTime=x=>x?new Date(x).toLocaleString('es-ES',{dateStyle:'medium',timeStyle:'short'}):'Sin fecha';
const day=x=>x?new Date(x).toLocaleDateString('es-ES',{dateStyle:'short'}):'—';
const short=x=>x?new Date(x).toLocaleDateString('sv-SE'):'';
const initials=s=>String(s||'').trim().split(/\s+/).slice(0,2).map(t=>t[0]||'').join('').toUpperCase();
const button=(label,action,id='',more='')=>`<button type="button" class="connected-secondary" data-action="${action}" data-id="${esc(id)}" ${more}>${label}</button>`;
const input=(label,name,value='',type='text',attrs='')=>`<label class="connected-field">${label}<input name="${name}" type="${type}" value="${esc(value)}" ${attrs}></label>`;
const select=(label,name,rows,selected='')=>`<label class="connected-field">${label}<select name="${name}">${rows.map(([value,title])=>`<option value="${esc(value)}" ${String(value)===String(selected)?'selected':''}>${esc(title)}</option>`).join('')}</select></label>`;
const note=t=>`<p class="connected-hint">${esc(t)}</p>`;
const show=(html)=>`<section class="connected-card business-360">${html}</section>`;

function renderTrainerOverview({inbox,requests,clients,occurrences,bookings,sessions,calendarMonth,manager}){
 const now=new Date(),today=new Date().toLocaleDateString('sv-SE');
 const visits=occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at)>=now).map(o=>({at:o.starts_at,kind:o.kind==='appointment'?'Cita':'Grupo',title:o.title,id:o.id,action:'detail-occurrence',detail:`${bookings.filter(b=>b.occurrence_id===o.id&&b.status==='booked').length} reservas`}));
 const plans=sessions.filter(s=>s.status==='scheduled'&&s.scheduled_date>=today).map(s=>({at:s.scheduled_date+'T12:00:00',kind:'Entrenamiento · sin hora',title:s.title,id:s.client_id,action:'detail-client',detail:clients.find(c=>c.id===s.client_id)?.name||'Deportista'}));
 const upcoming=[...visits,...plans].sort((a,b)=>a.at.localeCompare(b.at)).slice(0,8);
 const month=/^\d{4}-\d{2}$/.test(calendarMonth||'')?calendarMonth:today.slice(0,7);
 const [y,m]=month.split('-').map(Number),first=(new Date(y,m-1,1).getDay()+6)%7,n=new Date(y,m,0).getDate();
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const cells=Array.from({length:first+n},(_,i)=>{const d=i-first+1;if(d<1)return '<span class="business-calendar-empty" aria-hidden="true"></span>';
 const iso=month+'-'+String(d).padStart(2,'0');
 const matches=occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at).toLocaleDateString('sv-SE')===iso);
 return `<div class="business-calendar-cell"><button class="business-calendar-day" type="button" data-action="new-date-appointment" data-day="${iso}" aria-label="Añadir cita el ${d}">${d}</button>
 ${matches.map(o=>`<button type="button" class="business-calendar-event" data-action="detail-occurrence" data-id="${esc(o.id)}"><span>${o.kind==='appointment'?'Cita':'Grupo'}</span> ${esc(new Date(o.starts_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))} ${esc(o.title)}</button>`).join('')}</div>`;}).join('');
 return `<div class="business-home-columns">
 ${inbox||show('<h2>Quieren entrenar contigo</h2>'+note('No tienes permiso para gestionar solicitudes.'))}
 ${show(`<div class="business-panel-head"><div><h2>Próximas citas</h2><p>Citas, grupos y entrenamientos planificados.</p></div>${manager?button('Añadir planificación','add-planning'):''}</div>
 <div class="business-upcoming">${upcoming.map(o=>`<button class="business-upcoming-item" type="button" data-action="${o.action}" data-id="${esc(o.id)}"><small>${esc(o.kind)} · ${o.kind.includes('sin hora')?day(o.at):dateTime(o.at)}</small><strong>${esc(o.title)}</strong><span>${esc(o.detail)}</span></button>`).join('')||note('No tienes próximas citas ni entrenamientos.')}</div>`)}
 </div>
 ${show(`<div class="business-panel-head"><div><h2>Agenda de citas y grupos</h2><p>Selecciona un día libre para crear una cita o un evento para consultar sus detalles.</p></div><div class="heading-actions">${button('‹','calendar-prev')}${button(esc(title),'calendar-today')}${button('›','calendar-next')}</div></div>
 <div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div><div class="business-calendar-grid">${cells}</div>`)}`;
}

export function renderBusinessHome({org,clients=[],occurrences=[],bookings=[],sessions=[],templates=[],requests=[],manager=false,calendarMonth='',escapeHTML=esc}){
 const soon=occurrences.filter(o=>o.status==='active'&&new Date(o.starts_at)>new Date()).sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).slice(0,8);
 const stats=`<section class="business-stats"><div class="business-stat"><span>Deportistas</span><strong>${clients.length}</strong><small>En esta organización</small></div><div class="business-stat"><span>Sesiones programadas</span><strong>${occurrences.filter(o=>o.status==='active').length}</strong><small>Clases y citas</small></div><div class="business-stat"><span>Entrenamientos publicados</span><strong>${sessions.filter(s=>s.status==='scheduled').length}</strong><small>En diario de deportistas</small></div></section>`;
 const waiting=requests.filter(r=>r.status==='pending');
 const inbox=manager?show(`<div class="business-panel-head">
 <div><span class="connected-eyebrow">Solicitudes de alumnos</span><h2>Quieren entrenar contigo</h2>
 <p>Las peticiones llegan desde Repera. Acéptalas para añadir al atleta a tu centro y poder planificar sus entrenamientos.</p></div>
 <div class="business-inbox-tools"><span class="business-inbox-count">${waiting.length} pendientes</span>
 <button type="button" data-action="refresh-enrollments" class="connected-secondary" aria-label="Actualizar solicitudes">Actualizar</button></div></div>
 ${waiting.length?`<div class="business-inbox-list">${waiting.map(r=>`
 <article class="business-enrollment-row">
 <div class="business-enrollment-avatar">${/^https:\/\//.test(r.avatar_url||'')?`<img src="${esc(r.avatar_url)}" alt="" loading="lazy">`:esc(initials(r.name))}</div>
 <div class="business-enrollment-text"><strong>${esc(r.name||'Atleta')}</strong><small>${esc(r.email||'—')} · ${r.pass_kind==='appointment'?'Entrenamiento personal':'Clases'}</small>
 ${r.note?`<p>${esc(r.note)}</p>`:''}</div>
 <div class="business-enrollment-actions">
  <button type="button" class="connected-primary" data-action="approve-enrollment" data-id="${esc(r.id)}">Aceptar</button>
  <button type="button" class="connected-secondary" data-action="reject-enrollment" data-id="${esc(r.id)}">Rechazar</button>
 </div></article>`).join('')}</div>`:
 '<div class="business-inbox-empty">No tienes solicitudes pendientes. Las peticiones que envíen desde la app aparecerán aquí automáticamente al actualizar el panel.</div>'}`):'';
 const quick=manager?`<section class="business-quick-actions" aria-label="Acciones frecuentes del centro">
  <button type="button" data-workspace="planning"><span class="business-quick-icon" aria-hidden="true">＋</span>
  <strong>Planificar entrenamientos</strong><small>Un día, semana o varias fechas</small></button>
  <button type="button" data-workspace="clients"><span class="business-quick-icon" aria-hidden="true">♧</span>
  <strong>Gestionar deportistas</strong><small>Solicitudes, perfiles y bonos</small></button>
  <button type="button" data-workspace="services"><span class="business-quick-icon" aria-hidden="true">▦</span>
  <strong>Clases y reservas</strong><small>Horarios, grupos y aforo</small></button>
 </section>`:'';
 if(org?.kind==='personal_trainer')return renderTrainerOverview({inbox,requests,clients,occurrences,bookings,sessions,calendarMonth,manager});
 return `${stats}${quick}${inbox}${show(`<div class="business-panel-head"><div><h2>Próximas clases y citas</h2><p>Pulsa cualquier sesión para ver asistentes, horario, aforo y toda su configuración.</p></div>${button('Abrir calendario','open-class-calendar')}</div>
 <div class="business-cards">${soon.length?soon.map(o=>`<button type="button" class="business-class-tile" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong><small>${o.kind==='appointment'?'Cita 1:1':'Clase grupal'} · ${bookings.filter(b=>b.occurrence_id===o.id&&b.status==='booked').length}/${o.capacity} plazas</small><span class="business-tile-arrow">Ver detalle →</span></button>`).join(''):'<p>No hay próximas clases programadas.</p>'}</div>`)}`;
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

export function renderClient360({clients=[],selected=null,passes=[],bookings=[],occurrences=[],sessions=[],notices=[],sharedHistory=[],attendance=[],trainerActivityMonth='',trainerActivityDay='',manager=false,role='',trainer=false,escapeHTML=esc,clientSection='training'}){
 if(!selected)return show(`<div class="business-panel-head"><div>
 <span class="connected-eyebrow">DEPORTISTAS</span><h2>Clientes</h2>
 <p>Consulta cada ficha y sus entrenamientos autorizados. Las vinculaciones solo se completan al aceptar la invitación.</p></div></div>
 <div class="business-client-table-wrap"><table class="business-client-table"><thead><tr>
 <th>Atleta</th><th>Correo</th><th>Vinculación</th><th>Estado</th></tr></thead><tbody>
 ${clients.map(c=>`<tr role="link" tabindex="0" data-action="detail-client" data-id="${esc(c.id)}">
 <td><div class="business-client-person"><span class="business-avatar">${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?
 `<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}</span>
 <strong>${esc(c.name)}</strong></div></td><td>${esc(c.email||'—')}</td>
 <td>${c.account_deleted_at?'Cuenta eliminada · histórico':c.user_id?'Vinculado':'Pendiente de aceptación'}</td><td>${c.account_deleted_at?'Solo lectura':esc(c.status)}</td></tr>`).join('')||
 '<tr><td colspan="4">Todavía no hay clientes.</td></tr>'}
 </tbody></table></div>
 ${manager?`<form data-connected="client" class="business-client-add">
 <h3>Invitar a un cliente</h3>
 ${input('Nombre','name','','text','required minlength="2" maxlength="120"')}
 ${input('Correo electrónico','email','','email','required')}
 <button type="submit" class="connected-primary">Crear ficha y preparar invitación</button>
 <p class="connected-hint">El alta queda pendiente hasta que la persona acepte con su correo verificado. El envío del email requiere configurar el proveedor transaccional.</p></form>`:''}`);
 const c=clients.find(x=>x.id===selected);if(!c)return show('La persona seleccionada no está autorizada para este centro.');
  const archived=Boolean(c.account_deleted_at);
 const ownPasses=passes.filter(p=>p.client_id===c.id),
 ownBookings=bookings.filter(b=>b.client_id===c.id),
 ownSessions=sessions.filter(s=>s.client_id===c.id&&(archived||s.status==='scheduled'));
 const logged=athleteLoggedRows(sharedHistory);
 const ownAttendance=attendance.filter(a=>a.client_id===c.id);
 const tabs=`<nav class="business-client-tabs" aria-label="Ficha de cliente">
 ${[...[['training','Entrenamientos'],['data','Datos']],...(trainer?[]:[['bookings','Reservas']])].map(([id,name])=>
 `<button type="button" data-action="client-section" data-section="${id}" class="${clientSection===id?'active':''}"
 aria-current="${clientSection===id?'page':'false'}">${name}</button>`).join('')}</nav>`;
 const head=`${button('← Volver a clientes','back-clients')}<div class="business-profile-header"><span class="business-avatar large">
 ${c.avatar_url&&/^https:\/\//.test(c.avatar_url)?`<img src="${esc(c.avatar_url)}" alt="" loading="lazy">`:esc(initials(c.name))}
 </span><div><h2>${esc(c.name)}</h2><p>${esc(c.email)} · ${archived?'Cuenta eliminada · instantánea de solo lectura':c.user_id?'Cuenta vinculada':'Invitación pendiente'} </p></div>
 ${trainer?`<div class="business-profile-orientation"><span class="pa-eyebrow">Orientación de entrenamiento</span>${renderAthleteGuidance(logged,sharedHistory.length)}</div>`:''}
 ${!archived&&manager&&trainer&&c.status==='active'?button('Registrar sesión','trainer-session',c.id):''}${!archived&&manager&&!c.user_id?button('Preparar invitación','invite-client',c.id):''}${!archived&&manager&&trainer&&c.status!=='cancelled'?button('Finalizar relación','end-client',c.id):''}</div>`;
 let body='';
 if(clientSection==='training'){
  if(trainer){
   const currentMonth=/^\d{4}-\d{2}$/.test(trainerActivityMonth)?trainerActivityMonth:new Date().toLocaleDateString('sv-SE').slice(0,7);
   const currentDay=/^\d{4}-\d{2}-\d{2}$/.test(trainerActivityDay)?trainerActivityDay:new Date().toLocaleDateString('sv-SE');
   const daily=logged.filter(w=>localDay(w.started_at||w.finished_at)===currentDay);
   const planned=ownSessions.filter(s=>s.scheduled_date===currentDay);
   body=`<div class="trainer-client-actions">
    <p>Consulta lo registrado por el atleta y los entrenamientos programados. La actividad personal solo aparece si está compartida con el entrenador.</p>
    ${manager&&!archived?button('Crear planificación','add-planning',c.id):''}</div>
    <div class="pa-athlete-training-grid trainer-client-grid">
    ${renderAthleteActivity({month:currentMonth,selectedDay:currentDay,
      days:trainerDays({sharedHistory,sessions:ownSessions,attendance:ownAttendance}),
      workouts:daily,plannedSessions:planned,athleteId:c.id,actionNamespace:'trainer',
      canPlan:manager&&!archived,emptyText:'Los puntos señalan días con actividad compartida, entrenamientos programados o sesiones presenciales.'})}</div>
    ${ownAttendance.length?`<section class="business-detail-panel trainer-attendance-history"><h3>Sesiones presenciales registradas</h3>
      <div class="business-attendance-rows">${ownAttendance.slice(0,12).map(a=>`<div class="business-line"><strong>${dateTime(a.performed_at)}</strong><small>${esc(a.note||'Sesión realizada con el entrenador')}</small></div>`).join('')}</div></section>`:''}
    ${renderAthleteInsights(logged,sharedHistory.length,{showGuidance:false})}`;
  }else{
   body=`<div class="business-360-grid">
   <div class="business-detail-panel"><div class="business-panel-head"><h3>Planificación</h3>
   ${archived?'':button('Añadir entrenamientos','plan-client',c.id)}</div>
   ${ownSessions.length?ownSessions.map(s=>`<article class="business-line"><strong>${esc(s.title)}</strong>
   <small>${day(s.scheduled_date)} · ${(s.prescription?.blocks||[]).length} bloques</small>
   ${archived?'':button('Editar entrenamiento','edit-session',s.id)}${!archived&&manager?button('Eliminar','delete-session',s.id):''}</article>`).join(''):
   note('Aún no hay entrenamientos planificados.')}</div>
   <div class="business-detail-panel"><h3>Actividad compartida</h3>
   ${sharedHistory.length?`<p>${sharedHistory.length} sesiones compartidas con este centro.</p>
   ${renderSharedAthleteSessions(sharedHistory)}`:
   note('Solo se muestran actividades autorizadas por el atleta.')}</div></div>`;
  }
 }
 if(clientSection==='data'){
  body=`<div class="business-360-grid">
 <div class="business-detail-panel"><h3>Datos básicos</h3>
 <dl class="business-client-summary"><dt>Nombre</dt><dd>${esc(c.name)}</dd>
 <dt>Correo</dt><dd>${esc(c.email||'—')}</dd>
 <dt>Cuenta Repera</dt><dd>${archived?'Cuenta eliminada (solo histórico)':c.user_id?'Vinculada':'Pendiente de aceptación'}</dd>
 <dt>Estado</dt><dd>${archived?'Histórico · sin operaciones':esc(c.status)}</dd></dl>
  ${archived?'<p class="connected-hint">Registro congelado al eliminar la cuenta. Puedes consultar los datos y sesiones históricas, pero no modificar ni programar nuevas actividades.</p>':''}
 ${manager&&!archived?`<form data-connected="client-profile" class="business-form">
 ${input('Nombre','name',c.name,'text','required minlength="2" maxlength="120"')}
 ${input('Correo','email',c.email,'email','required')}
 ${select('Estado','status',['lead','trial','active','paused',...(trainer&&c.status!=='cancelled'?[]:['cancelled'])].map(v=>[v,v]),c.status)}
 <input type="hidden" name="client" value="${esc(c.id)}">
 <button type="submit" class="connected-primary">Guardar datos básicos</button></form>`:''}</div>
 <div class="business-detail-panel"><h3>Bonos y saldo</h3>
 ${ownPasses.length?ownPasses.map(p=>`<article class="business-line">
 <strong>${p.kind==='class'?'Clases':'Citas'}</strong>
 <small>${p.remaining_credits}/${p.total_credits} disponibles · ${day(p.valid_until)}</small></article>`).join(''):
 note('Sin bonos activos.')}</div></div>`;
 }
 if(clientSection==='bookings'){
  body=`<div class="business-360-grid">
 <div class="business-detail-panel"><h3>Reservas recientes</h3>
 ${ownBookings.length?ownBookings.map(b=>{const o=occurrences.find(o=>o.id===b.occurrence_id);
 return `<article class="business-line"><strong>${esc(o?.title||'Clase')}</strong>
 <small>${dateTime(o?.starts_at)} · ${esc(b.status)}</small></article>`;}).join(''):
 note('Sin reservas.')}</div>
 <div class="business-detail-panel"><h3>Sesiones profesionales recientes</h3>
 ${ownSessions.length?ownSessions.map(t=>`<article class="business-line"><strong>${esc(t.title)}</strong>
 <small>${day(t.scheduled_date)} · ${esc(t.status)}</small></article>`).join(''):
 note('Sin sesiones profesionales.')}</div></div>`;
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
  const booked=bookings.filter(b=>b.occurrence_id===o.id&&b.status==='booked'),meta=index.get(o.id)||{},future=new Date(o.starts_at)>new Date();
  const available=passes.filter(p=>p.status==='active'&&p.kind===o.kind&&p.remaining_credits>0&&new Date(p.valid_from)<=new Date(o.starts_at)&&new Date(p.valid_until)>=new Date(o.starts_at));
  const eligible=clients.filter(c=>!c.account_deleted_at&&available.some(p=>p.client_id===c.id)&&!booked.some(b=>b.client_id===c.id));
  return show(`${button('← Volver a clases','back-classes')}<div class="business-profile-header"><span class="business-class-mark" style="background:${/^#[0-9a-f]{6}$/i.test(meta.color||'')?meta.color:'#22834d'}"></span><div><h2>${esc(o.title)}</h2><p>${dateTime(o.starts_at)} · ${esc(meta.location||'Ubicación sin definir')} · ${booked.length}/${o.capacity} plazas</p></div></div>
  <div class="business-360-grid"><div class="business-detail-panel"><h3>Configuración de la clase</h3>${manager&&future&&o.status==='active'?`<form data-connected="edit-occurrence" class="business-form"><input type="hidden" name="id" value="${esc(o.id)}">${input('Nombre','title',o.title,'text','required minlength="2" maxlength="120"')}${input('Inicio','start',new Date(o.starts_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Fin','end',new Date(o.ends_at).toLocaleString('sv-SE',{hour12:false}).replace(' ','T').slice(0,16),'datetime-local','required')}${input('Aforo','capacity',o.capacity,'number',`min="${Math.max(1,booked.length)}" max="200" required`)}${input('Lugar','location',meta.location||'','text','maxlength="250"')}${input('Color','color',meta.color||'#22834d','color')}${input('Imagen (URL)','image',meta.image_url||'','url','maxlength="2000"')}<label class="connected-field">Descripción<textarea name="description" rows="3" maxlength="2000">${esc(meta.description||'')}</textarea></label><button class="connected-primary">Guardar cambios</button></form><p>${button('Cancelar clase y devolver bonos','cancel-occurrence',o.id)}</p>`:`<p>${esc(meta.description||'Sin descripción')}</p><p>Estado: ${esc(o.status)}</p>`}</div>
  <div class="business-detail-panel"><h3>Asistentes (${booked.length})</h3>${booked.map(b=>`<div class="business-roster"><span class="business-avatar">${esc(initials(clients.find(c=>c.id===b.client_id)?.name))}</span><div><strong>${esc(clients.find(c=>c.id===b.client_id)?.name||'Deportista')}</strong><small>Reserva confirmada</small></div>${manager&&future?button('Quitar','remove-booking',b.id):''}</div>`).join('')||note('Nadie inscrito todavía.')}
  ${manager&&future&&o.status==='active'?`<form data-connected="enroll-client" class="business-form"><input type="hidden" name="occurrence" value="${esc(o.id)}">${select('Cliente con bono válido','pass',eligible.flatMap(c=>available.filter(p=>p.client_id===c.id).map(p=>[p.id,`${c.name} · ${p.remaining_credits} sesiones disponibles`])))}<button class="connected-primary" ${!eligible.length||booked.length>=o.capacity?'disabled':''}>Añadir participante</button></form>${note('El alta consume un crédito del bono válido; la baja administrativa lo devuelve.')}`:''}</div>
  <div class="business-detail-panel"><h3>Planificación de la sesión</h3>${note('Puedes publicar el WOD de esta clase para los deportistas vinculados. Sus entrenamientos seguirán siendo individuales.')} ${manager&&booked.length?button('Preparar movimientos para esta clase','publish-class-plan',o.id):''}
  ${manager&&classEditor?`<form data-connected="publish-class-plan" class="business-form"><input type="hidden" name="occurrence" value="${esc(o.id)}">${input('Título del entrenamiento','title',o.title,'text','required minlength="2" maxlength="120"')}${editorMarkup(emptyPrescription())}<label class="connected-field">Indicaciones<textarea name="instructions" rows="3" maxlength="10000"></textarea></label><button class="connected-primary" type="submit">Publicar para los inscritos vinculados</button></form>`:''}</div>
  <div class="business-detail-panel"><h3>Información y operaciones</h3><p>Tipo: ${o.kind==='class'?'Clase grupal':'Cita individual'}</p><p>Repetición: ${esc(meta.repeat_rule||'Sin repetir')}</p>${meta.image_url?`<img class="business-class-image" src="${esc(meta.image_url)}" loading="lazy" alt="Imagen de la clase">`:''}</div></div>`);
 }
 const active=occurrences.filter(o=>o.status==='active');
 const [y,m]=(calendarMonth||new Date().toLocaleDateString('sv-SE').slice(0,7)).split('-').map(Number);
 const title=new Date(y,m-1,1).toLocaleDateString('es-ES',{month:'long',year:'numeric'});
 const firstDay=(new Date(y,m-1,1).getDay()+6)%7;
 const countDays=new Date(y,m,0).getDate();
 const calendar=Array.from({length:firstDay+countDays},(_,i)=>i-firstDay+1).map(d=>d<1?'<span class="business-calendar-empty"></span>':`<div class="business-calendar-cell"><strong>${d}</strong>${active.filter(o=>{const date=new Date(o.starts_at);return date.getFullYear()===y&&date.getMonth()===m-1&&date.getDate()===d}).map(o=>`<button type="button" style="--class-color:${esc(index.get(o.id)?.color||'#22834d')}" class="business-calendar-event" data-action="detail-occurrence" data-id="${esc(o.id)}">${esc(new Date(o.starts_at).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit'}))} ${esc(o.title)}</button>`).join('')}</div>`).join('');
 return show(`<div class="business-panel-head"><div><h2>Clases, grupos y reservas</h2><p>Gestiona sesiones desde el calendario o el listado. Accede a cada clase para modificarla.</p></div><div class="heading-actions">${button('Calendario','calendar-mode','','data-mode="calendar"')}${button('Lista','calendar-mode','','data-mode="list"')}</div></div>
 ${listMode==='calendar'?`<div class="business-calendar-title">${button('‹','calendar-prev')}<strong>${esc(title)}</strong>${button('›','calendar-next')}</div><div class="business-calendar-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div><div class="business-calendar-grid">${calendar}</div>`:
 `<div class="business-cards">${active.sort((a,b)=>a.starts_at.localeCompare(b.starts_at)).map(o=>`<button class="business-class-tile" data-action="detail-occurrence" data-id="${esc(o.id)}"><span class="business-class-date">${dateTime(o.starts_at)}</span><strong>${esc(o.title)}</strong><small>${esc(index.get(o.id)?.location||'Sin lugar')} · ${bookings.filter(b=>b.occurrence_id===o.id&&b.status==='booked').length}/${o.capacity} participantes</small><span class="business-tile-arrow">Gestionar →</span></button>`).join('')||note('No hay clases.')}</div>`}
 <div class="business-360-grid"><div class="business-detail-panel"><h3>Grupos</h3>${groups.map(g=>`<button type="button" class="business-group-row" data-action="detail-group" data-id="${esc(g.id)}"><strong>${esc(g.name)}</strong><small>${esc(g.description||'')}</small><span>Gestionar →</span></button>`).join('')||note('Puedes agrupar deportistas por programa o nivel.')} ${manager?`<form data-connected="create-group" class="business-form">${input('Nuevo grupo','name','','text','required minlength="2" maxlength="100"')}${input('Descripción','description','','text','maxlength="500"')}<button class="connected-secondary">Crear grupo</button></form>`:''}</div>
 <div class="business-detail-panel"><h3>Nueva clase o cita</h3>${manager?`<form data-connected="service-occurrence" class="business-form">${select('Tipo','kind',[['class','Clase grupal'],['appointment','Cita individual']])}${input('Nombre','title','','text','required minlength="2" maxlength="120"')}${input('Inicio','start','','datetime-local','required')}${input('Fin','end','','datetime-local','required')}${input('Aforo','capacity','1','number','min="1" max="200" required')}${select('Entrenador','coach',coaches.map(c=>[c.user_id,c.label||c.user_id.slice(0,8)]))}${select('Repetición','repeat',[['none','Una vez'],['daily','Cada día'],['weekly','Cada semana'],['weekdays','Lunes a viernes']])}${input('Número de sesiones','repeatCount','1','number','min="1" max="52" required')}<button class="connected-primary">Crear sesiones</button></form>`:note('No tienes permiso para crear horarios.')}</div></div>`);
}