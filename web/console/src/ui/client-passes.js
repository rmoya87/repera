// Ficha cliente → Bonos: columnas bono | actividad; alta/renovar/cambiar en modal; Finalizar en la card.
import {renderAssignOfflinePassForm,passProvenanceLabel} from './gym-pass-panel.js';

const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
const dateTime=s=>s?new Date(s).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}):'—';

function passStatus(p){
 if(p.status==='cancelled')return ['Cancelado','muted'];
 if(Date.parse(p.valid_until)<=Date.now())return ['Caducado','muted'];
 if(p.remaining_credits<=0&&(p.total_credits||0)<9000)return ['Agotado','info'];
 return ['Activo','ok'];
}
function creditLabel(p){
 if(p.remaining_credits>=9000||p.total_credits>=9000)return 'Ilimitado';
 return `${p.remaining_credits}/${p.total_credits}`;
}
function usedCredits(p){
 if(p.total_credits>=9000)return null;
 return Math.max(0,(p.total_credits||0)-(p.remaining_credits||0));
}
function progressPct(p){
 if(p.total_credits>=9000||!p.total_credits)return 0;
 return Math.min(100,Math.round(((p.total_credits-p.remaining_credits)/p.total_credits)*100));
}
function actionLabel(a){
 return ({add_credits:'Créditos añadidos',reset_remaining:'Saldo restaurado',extend_validity:'Validez ampliada'})[a]||a;
}

function buildActivity({clientId,passes=[],attendance=[],bookings=[],occurrences=[],passEvents=[]}){
 const passIds=new Set(passes.map(p=>p.id));
 const rows=[];
 for(const a of attendance.filter(x=>x.client_id===clientId)){
  rows.push({at:a.performed_at,kind:'spend',title:'Sesión registrada',
   detail:a.booking_id?'Reserva ya descontada · no se vuelve a cobrar':`1 crédito · ${a.note||'Presencial'}`,
   passId:a.pass_id});
 }
 for(const b of bookings.filter(x=>x.client_id===clientId&&x.pass_id&&passIds.has(x.pass_id))){
  const o=occurrences.find(x=>x.id===b.occurrence_id);
  const spent=['booked','attended','no_show'].includes(b.status);
  if(!spent)continue;
  rows.push({at:b.booked_at||o?.starts_at,kind:'spend',
   title:b.status==='attended'?'Asistió · crédito usado':b.status==='no_show'?'No presentado · crédito usado':'Reserva · crédito descontado',
   detail:`${o?.title||'Cita/clase'} · ${dateTime(o?.starts_at)}`,passId:b.pass_id});
 }
 for(const e of passEvents.filter(x=>passIds.has(x.pass_id))){
  rows.push({at:e.created_at,kind:'manage',title:actionLabel(e.action),
   detail:e.action==='extend_validity'
    ?`Hasta ${day(e.new_expiry)}`
    :`${e.previous_remaining}→${e.new_remaining} créditos`,
   passId:e.pass_id});
 }
 for(const p of passes){
  rows.push({at:p.created_at||p.valid_from,kind:'grant',title:'Bono asignado',
   detail:`${creditLabel(p)} · ${passProvenanceLabel(p)} · hasta ${day(p.valid_until)}`,passId:p.id});
 }
 return rows.filter(r=>r.at).sort((a,b)=>String(b.at).localeCompare(String(a.at)));
}

/**
 * Panel completo de bonos en ficha de cliente.
 */
export function renderClientPassesPanel({
 client,passes=[],offers=[],attendance=[],bookings=[],occurrences=[],passEvents=[],
 manager=false,trainer=false,busy=false,archived=false,
}){
 if(!client)return '';
 const own=passes.filter(p=>p.client_id===client.id)
  .sort((a,b)=>String(b.created_at||b.valid_until).localeCompare(String(a.created_at||a.valid_until)));
 const active=own.filter(p=>p.status==='active'&&Date.parse(p.valid_until)>Date.now());
 const kindFilter=trainer?'appointment':null;
 const activity=buildActivity({clientId:client.id,passes:own,attendance,bookings,occurrences,passEvents});
 const usable=active.filter(p=>p.remaining_credits>0||p.remaining_credits>=9000);

 const cards=own.length?own.map(p=>{
  const [st,tone]=passStatus(p);
  const used=usedCredits(p);
  const offer=offers.find(o=>o.id===p.offer_id);
  const isLive=p.status==='active'&&Date.parse(p.valid_until)>Date.now();
  return `<article class="pt-pass-card ${isLive?'':'is-dim'}">
   <div class="pt-pass-card-top">
    <div>
     <strong>${esc(offer?.name||(p.kind==='class'?'Bono clases':'Bono citas'))}</strong>
     <small>${esc(passProvenanceLabel(p))} · ${p.kind==='class'?'Clases':'Citas 1:1'}</small>
    </div>
    <span class="business-status-badge tone-${tone}"><span class="business-status-dot" aria-hidden="true"></span>${st}</span>
   </div>
   <div class="pt-pass-meter" aria-hidden="true"><span style="width:${progressPct(p)}%"></span></div>
   <div class="pt-pass-stats">
    <div><span class="pt-data-label">Saldo</span><strong>${esc(creditLabel(p))}</strong></div>
    <div><span class="pt-data-label">Usadas</span><strong>${used==null?'—':used}</strong></div>
    <div><span class="pt-data-label">Desde</span><strong>${day(p.valid_from||p.created_at)}</strong></div>
    <div><span class="pt-data-label">Hasta</span><strong>${day(p.valid_until)}</strong></div>
   </div>
   ${p.payment_method||p.paid_at||Number.isFinite(p.paid_amount_cents)?`<p class="pt-pass-pay"><small>Pago: ${esc(({card:'Tarjeta',transfer:'Transferencia',cash:'Efectivo',other:'Otro',complimentary:'Cortesía'})[p.payment_method]||passProvenanceLabel(p))}${p.paid_at?' · '+day(p.paid_at):''}${Number.isFinite(p.paid_amount_cents)?' · '+new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(p.paid_amount_cents/100):''}${p.payment_note?' · '+esc(p.payment_note):''}</small></p>`:''}
   ${manager&&!archived&&isLive?`<div class="pt-pass-actions">
    <div class="pt-pass-actions-row">
     <button type="button" class="connected-primary" data-action="open-assign-pass" data-id="${esc(client.id)}" data-mode="renew">Renovar / cambiar</button>
     <button type="button" class="connected-secondary pt-pass-finish" data-action="finalize-pass" data-id="${esc(p.id)}" data-client="${esc(client.id)}" ${busy?'disabled':''}>Finalizar sin renovar</button>
    </div>
    ${p.issuance_type==='complimentary'?`
     <form data-connected="manage-pass" class="pt-pass-manage">
      <input type="hidden" name="pass" value="${esc(p.id)}">
      <input type="hidden" name="op" value="add_credits">
      <label class="connected-field">Añadir<input name="amount" type="number" min="1" max="100" value="1" required></label>
      <button type="submit" class="connected-secondary" ${busy?'disabled':''}>Sumar</button>
     </form>
     <form data-connected="manage-pass" class="pt-pass-manage">
      <input type="hidden" name="pass" value="${esc(p.id)}">
      <input type="hidden" name="op" value="extend_validity">
      <label class="connected-field">Hasta<input name="until" type="date" required></label>
      <button type="submit" class="connected-secondary" ${busy?'disabled':''}>Ampliar</button>
     </form>`:''}
   </div>`:''}
  </article>`;
 }).join(''):'<p class="business-empty">Este cliente aún no tiene bonos.</p>';

 const sessionBlock=trainer&&manager&&!archived&&usable.length?`<section class="pt-pass-section pt-pass-session">
  <h3>Registrar sesión gastada</h3>
  <form class="business-form" data-connected="trainer-attendance">
   <input type="hidden" name="client" value="${esc(client.id)}">
   <label class="connected-field">Bono<select name="pass" required>
    ${usable.map(p=>`<option value="${esc(p.id)}">${esc(creditLabel(p))} · hasta ${day(p.valid_until)}</option>`).join('')}
   </select></label>
   <label class="connected-field">Notas<textarea name="note" rows="2" maxlength="1000" placeholder="Técnica, fuerza…"></textarea></label>
   <button class="connected-primary" ${busy?'disabled':''}>Confirmar sesión</button>
  </form>
 </section>`:'';

 const timeline=activity.length?`<div class="pt-pass-timeline">${activity.slice(0,40).map(r=>`<article class="pt-pass-event is-${esc(r.kind)}">
  <div class="pt-pass-event-dot" aria-hidden="true"></div>
  <div><strong>${esc(r.title)}</strong><small>${dateTime(r.at)} · ${esc(r.detail)}</small></div>
 </article>`).join('')}</div>`:'<p class="business-empty">Sin movimientos todavía.</p>';

 return `<div class="pt-client-passes">
  <div class="business-panel-head pt-pass-head">
   <div><h3>Bonos</h3>
    <p>${active.length?`${active.length} activo${active.length===1?'':'s'}`:'Ninguno activo'}</p></div>
   ${!archived&&manager?`<button type="button" class="connected-primary" data-action="open-assign-pass" data-id="${esc(client.id)}" data-mode="${active.length?'renew':'new'}">Alta bono</button>`:''}
  </div>
  ${archived?'<p class="connected-hint">Cuenta archivada: solo lectura.</p>':''}
  <div class="pt-pass-split">
   <section class="pt-pass-col pt-pass-col-left" aria-label="Bonos del cliente">
    <h4 class="pt-pass-col-title">Bono del cliente</h4>
    <div class="pt-pass-stack">${cards}</div>
    ${sessionBlock}
   </section>
   <section class="pt-pass-col pt-pass-col-right" aria-label="Actividad">
    <h4 class="pt-pass-col-title">Actividad</h4>
    ${timeline}
   </section>
  </div>
 </div>`;
}

/** Modal de alta / renovación / cambio de bono. */
export function renderAssignPassModal({
 client,offers=[],manager=false,busy=false,trainer=false,mode='new',
}){
 if(!client||!manager)return '';
 const kindFilter=trainer?'appointment':null;
 const renew=mode==='renew';
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-assign-pass-dialog" role="dialog" aria-modal="true" aria-label="${renew?'Renovar o cambiar bono':'Alta de bono'}">
  <div class="business-dialog-header pt-sheet-head"><div>
   <span class="pt-sheet-kicker">${esc(client.name)}</span>
   <h2>${renew?'Renovar / cambiar bono':'Alta de bono'}</h2>
  </div>
  <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <div class="pt-sheet-hero"><p>${renew
    ?'Asigna una tarifa nueva tras el cobro. El ciclo anterior queda en el historial.'
    :'Elige la tarifa cobrada fuera de Repera (o abre cortesía abajo).'}</p></div>
   ${renderAssignOfflinePassForm({
    clients:[client],offers,clientId:client.id,manager,busy,kindFilter,
    emptyOffersHint:trainer?'No hay planes de citas activos. Créalos en Planes.':'No hay planes activos. Créalos en Planes.',
   })}
   <details class="trainer-expander pt-courtesy-box"><summary>+ Cortesía (sin cobro)</summary>
    <form data-connected="courtesy-pass" class="business-form">
     <input type="hidden" name="client" value="${esc(client.id)}">
     <input type="hidden" name="kind" value="${trainer?'appointment':'class'}">
     <div class="trainer-form-cols">
      <label class="connected-field">Sesiones<input name="credits" type="number" min="1" max="100" value="1" required></label>
      <label class="connected-field">Válido hasta<input name="until" type="date" required></label>
     </div>
     <button type="submit" class="connected-secondary" ${busy?'disabled':''}>Dar cortesía</button>
    </form>
   </details>
  </div>
 </section></div>`;
}
