// Consola de bonos de entrenador personal: precios ≠ pagos; registro presencial ≠ reserva.
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=n=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(n||0)/100);
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
export const BILLING_LABEL={
 session_pack:'Bono por sesiones',
 monthly:'Mensual',
 unlimited:'Ilimitado',
 time_slot:'Franja horaria'
};
const WEEKDAYS=[['1','Lun'],['2','Mar'],['3','Mié'],['4','Jue'],['5','Vie'],['6','Sáb'],['7','Dom']];
const minuteToTime=m=>{
 const n=Math.max(0,Math.min(1439,Number(m)||0));
 return `${String(Math.floor(n/60)).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`;
};
const timeToMinute=t=>{
 const [h,m]=String(t||'09:00').split(':').map(Number);
 return (Math.min(23,h||0)*60)+(Math.min(59,m||0));
};
export function formatSlotSummary(o){
 if((o.billing_model||'')!=='time_slot')return '';
 const days=(o.slot_weekdays||[]).map(d=>WEEKDAYS.find(w=>w[0]===String(d))?.[1]||d).join('·');
 return `${days||'—'} ${minuteToTime(o.slot_start_minute)}–${minuteToTime(o.slot_end_minute)} · ${o.access_scope==='gym_access'?'Acceso gym':'Citas entrenador'}`;
}
export function offerSummary(o){
 const model=o.billing_model||'session_pack';
 if(model==='unlimited')return `Ilimitado · ${o.validity_days} días · ${money(o.price_cents)}`;
 if(model==='monthly')return `Mensual · ${o.validity_days} días · ${money(o.price_cents)}`;
 if(model==='time_slot')return `Franja · ${formatSlotSummary(o)} · ${o.validity_days} días · ${money(o.price_cents)}`;
 return `${o.credits} sesiones · ${o.validity_days} días · ${money(o.price_cents)}`;
}
/** Clientes a los que se puede asignar bono: ficha activa, no archivada (vinculado o pendiente). */
export function assignableClients(clients=[]){
 return clients.filter(c=>!c.account_deleted_at&&['active','trial','lead','paused'].includes(c.status));
}
export function trainerSeatInfo({clients=[],trials=[],plans=[]}){
 const record=trials[0]||{},now=Date.now();
 const paid=record.paid_plan&&Date.parse(record.paid_until||'')>now
   ?plans.find(p=>p.plan_key===record.paid_plan&&p.audience==='personal_trainer'):null;
 const inTrial=Date.parse(record.trial_ends_at||'')>now;
 const max=paid?(paid.max_clients??Infinity):(inTrial?5:0);
 const used=clients.filter(c=>c.user_id&&['active','trial','paused'].includes(c.status)).length;
 return {max,used,left:Math.max(0,max-used),canLink:used<max,
  label:paid?paid.title:(inTrial?'Prueba gratuita · hasta 5':'Sin plan activo'),
  paid:!!paid,trial:inTrial};
}

function eurosFromCents(cents){
 const n=Number(cents||0)/100;
 return Number.isFinite(n)?String(n):'';
}

/** Formulario crear/editar plan (modal). Misma UX que la tarjeta de Ajustes → Plan. */
export function renderPassOfferForm({
 busy=false,includeGymScope=false,defaultKind='appointment',offer=null,mode='create',
}={}){
 const editing=mode==='edit'&&offer;
 const kind=(editing?offer.kind:defaultKind)==='class'?'class':'appointment';
 const billing=editing?(offer.billing_model||'session_pack'):'session_pack';
 const name=editing?(offer.name||''):'';
 const credits=editing&&offer.credits<9000?offer.credits:10;
 const validity=editing?(offer.validity_days||90):90;
 const price=editing?eurosFromCents(offer.price_cents):'';
 const days=new Set((editing?.slot_weekdays||[1,2,3,4,5]).map(Number));
 const slotStart=minuteToTime(editing?.slot_start_minute??540);
 const slotEnd=minuteToTime(editing?.slot_end_minute??720);
 const scope=editing?.access_scope==='gym_access'?'gym_access':'trainer_appointments';
 const action=editing?'update-pass-offer':'create-pass-offer';
 const billOpt=(v,label)=>`<option value="${v}" ${billing===v?'selected':''}>${label}</option>`;
 return `<form data-connected="${action}" class="business-form pt-tariff-form" data-pass-offer-form>
 ${editing?`<input type="hidden" name="id" value="${esc(offer.id)}">`:''}
 <label class="connected-field">Nombre<input name="name" minlength="2" maxlength="120" placeholder="Bono 10 · Mañanas · Mensual" value="${esc(name)}" required></label>
 <label class="connected-field">Tipo de plan<select name="billing" required data-billing-select ${editing?'disabled':''}>
  ${billOpt('session_pack','Bono por sesiones')}
  ${billOpt('monthly','Pago mensual')}
  ${billOpt('unlimited','Sesiones ilimitadas')}
  ${billOpt('time_slot','Franja horaria')}
 </select></label>
 ${editing?`<input type="hidden" name="billing" value="${esc(billing)}">`:''}
 ${includeGymScope?`<label class="connected-field">Uso del plan<select name="kind" ${editing?'disabled':''}>
  <option value="class" ${kind==='class'?'selected':''}>Clases / acceso gym</option>
  <option value="appointment" ${kind==='appointment'?'selected':''}>Citas 1:1</option>
 </select></label>${editing?`<input type="hidden" name="kind" value="${esc(kind)}">`:''}`:`<input name="kind" type="hidden" value="${kind}">`}

 <div class="trainer-form-cols" data-billing-fields="session_pack" ${billing!=='session_pack'?'hidden':''}>
  <label class="connected-field">Nº de sesiones<input name="credits" type="number" min="1" max="9999" value="${esc(credits)}"></label>
  <label class="connected-field">Validez (días)<input name="validityDays" type="number" min="1" max="730" value="${esc(billing==='session_pack'?validity:90)}"></label>
  <label class="connected-field">Precio (€)<input name="price" type="number" min="0" max="100000" step=".01" value="${esc(billing==='session_pack'?price:'')}"></label>
 </div>

 <div class="trainer-form-cols" data-billing-fields="monthly" ${billing!=='monthly'?'hidden':''}>
  <label class="connected-field">Duración (días)<input name="validityDaysMonthly" type="number" min="1" max="730" value="${esc(billing==='monthly'?validity:30)}"></label>
  <label class="connected-field">Precio del periodo (€)<input name="priceMonthly" type="number" min="0" max="100000" step=".01" value="${esc(billing==='monthly'?price:'')}"></label>
  <p class="connected-hint full">Sin cupo de sesiones: el acceso vale durante el periodo. Cobro externo.</p>
 </div>

 <div class="trainer-form-cols" data-billing-fields="unlimited" ${billing!=='unlimited'?'hidden':''}>
  <label class="connected-field">Validez del acceso (días)<input name="validityDaysUnlimited" type="number" min="1" max="730" value="${esc(billing==='unlimited'?validity:365)}"></label>
  <label class="connected-field">Precio (€)<input name="priceUnlimited" type="number" min="0" max="100000" step=".01" value="${esc(billing==='unlimited'?price:'')}"></label>
  <p class="connected-hint full">Sin límite práctico de sesiones durante la validez.</p>
 </div>

 <div class="trainer-slot-fields" data-billing-fields="time_slot" ${billing!=='time_slot'?'hidden':''}>
  <label class="connected-field">Qué incluye<select name="accessScope">
   <option value="trainer_appointments" ${scope!=='gym_access'?'selected':''}>Solo citas con el entrenador en esa franja</option>
   ${includeGymScope?`<option value="gym_access" ${scope==='gym_access'?'selected':''}>Acceso al gimnasio / clases en esa franja</option>`:''}
  </select></label>
  <fieldset class="pt-slot-days"><legend>Días de la franja</legend>
   <div class="pt-slot-day-grid">${WEEKDAYS.map(([v,l])=>`<label><input type="checkbox" name="slotWeekdays" value="${v}" ${days.has(Number(v))?'checked':''}><span>${l}</span></label>`).join('')}</div>
  </fieldset>
  <div class="trainer-form-cols">
   <label class="connected-field">Desde<input name="slotStart" type="time" value="${esc(slotStart)}"></label>
   <label class="connected-field">Hasta<input name="slotEnd" type="time" value="${esc(slotEnd)}"></label>
   <label class="connected-field">Validez (días)<input name="validityDaysSlot" type="number" min="1" max="730" value="${esc(billing==='time_slot'?validity:90)}"></label>
   <label class="connected-field">Precio (€)<input name="priceSlot" type="number" min="0" max="100000" step=".01" value="${esc(billing==='time_slot'?price:'')}"></label>
  </div>
  <p class="connected-hint full">Al reservar, solo podrá usar citas (o clases/gym) que empiecen dentro de esta franja.</p>
 </div>

 ${editing?`<label class="connected-field">Estado<select name="isActive">
  <option value="true" ${offer.is_active?'selected':''}>Publicado</option>
  <option value="false" ${offer.is_active?'':'selected'}>Desactivado</option>
 </select></label>`:''}

 <p class="connected-hint" data-billing-hint>Así se verá el plan en tu catálogo. El cobro sigue siendo externo a Repera.</p>
 <button class="connected-primary" ${busy?'disabled':''}>${editing?'Guardar cambios':'Publicar plan'}</button>
 </form>`;
}

/** @deprecated alias — el alta va por modal. */
export function renderTrainerPassOfferForm(opts={}){
 return renderPassOfferForm(opts);
}

export function renderPassOfferModal({busy=false,includeGymScope=false,defaultKind='appointment',offer=null}={}){
 const editing=!!offer;
 return `<div class="business-overlay pt-overlay"><section class="business-dialog pt-sheet pt-plan-offer-dialog" role="dialog" aria-modal="true" aria-label="${editing?'Editar plan':'Nuevo plan'}">
  <div class="business-dialog-header pt-sheet-head"><div><span class="pt-sheet-kicker">Planes</span><h2>${editing?'Editar plan':'Nuevo plan'}</h2></div>
   <button type="button" class="icon-button pt-sheet-close" data-action="close-business-dialog" aria-label="Cerrar">×</button></div>
  <div class="business-dialog-scroll pt-sheet-body">
   <div class="pt-plan-preview business-price" aria-hidden="true">
    <h3>${esc(editing?(offer.name||'Plan'):'Vista previa')}</h3>
    <strong>${esc(editing?money(offer.price_cents):'—')}<small> · cobro externo</small></strong>
    <p>${esc(editing?offerSummary(offer):'Completa el formulario: el plan aparecerá como esta tarjeta en Planes.')}</p>
   </div>
   ${renderPassOfferForm({busy,includeGymScope,defaultKind,offer,mode:editing?'edit':'create'})}
  </div>
 </section></div>`;
}

export function renderOfferPriceCards({offers=[],manager=false,peopleLabel='clientes',hideCreateCard=false}={}){
 const cards=offers.map(o=>`<article class="business-price ${o.is_active?'':'is-inactive'}">
  <h3>${esc(o.name)}</h3>
  <strong>${esc(money(o.price_cents))}<small> · cobro externo</small></strong>
  <p>${esc(BILLING_LABEL[o.billing_model]||'Plan')} · ${esc(offerSummary(o))}</p>
  <p>${o.is_active?'Publicado':'Desactivado'}${o.kind==='class'?' · Clases/gym':' · Citas'}</p>
  ${manager?`<div class="pt-plan-card-actions">
   <button type="button" class="connected-secondary" data-action="open-edit-plan-modal" data-id="${esc(o.id)}">Editar</button>
   <button type="button" class="connected-secondary" data-action="toggle-pass-offer" data-id="${esc(o.id)}" data-active="${o.is_active?'true':'false'}">${o.is_active?'Desactivar':'Activar'}</button>
  </div>`:''}
 </article>`).join('');
 const create=!hideCreateCard&&manager?`<button type="button" class="business-price pt-plan-create-card" data-action="open-create-plan-modal">
  <h3>+ Crear plan</h3>
  <strong>—</strong>
  <p>Bono, mensual, ilimitado o franja. Se mostrará aquí como a tus ${esc(peopleLabel)}.</p>
 </button>`:'';
 return `<div class="business-prices pt-offer-prices">${cards||''}${create}</div>${!offers.length&&!manager?'<p class="business-empty">No hay planes publicados.</p>':!offers.length&&manager&&hideCreateCard?'<p class="business-empty">Todavía no hay planes. Pulsa Crear plan.</p>':''}`;
}

export {timeToMinute,minuteToTime};

export function renderTrainerPassPanel({clients=[],passes=[],offers=[],seat,manager=false}){
 return `<div class="trainer-pass-dashboard pt-plans-layout">
 <section class="connected-card business-subscriptions pt-plans-catalog">
  <div class="business-panel-head pt-plans-head">
   <div><h2>Planes</h2>
    <p>Así los verás tú y tus clientes: bono, mensual, ilimitado o franja. El precio no implica cobro en Repera.</p></div>
   ${manager?`<button type="button" class="connected-primary" data-action="open-create-plan-modal">Crear plan</button>`:''}
  </div>
  <div class="trainer-seats"><strong>${seat?.used??0} / ${seat?.max===Infinity?'∞':(seat?.max??0)} clientes vinculados</strong>
   <span>${esc(seat?.label||'—')} · ${seat?.left===Infinity?'Sin límite de plazas':(seat?.left??0)+' plazas disponibles'}</span></div>
  ${renderOfferPriceCards({offers,manager,peopleLabel:'clientes',hideCreateCard:true})}
 </section>
 <aside class="connected-card pt-plans-assigned">
  <h2>Planes asignados</h2>
  <p class="connected-hint">Para asignar un plan, abre la ficha del cliente → Bonos.</p>
  <div class="pt-assigned-grid">
   ${passes.length?passes.map(p=>`<article class="pt-assigned-tile">
    <strong>${esc(clients.find(c=>c.id===p.client_id)?.name||'Cliente')}</strong>
    <small>${p.remaining_credits>=9000?'Ilimitado':`${p.remaining_credits}/${p.total_credits}`} · ${p.issuance_type==='manual_offline'?'Externo':p.issuance_type==='complimentary'?'Cortesía':'Plan'}</small>
    <small>Hasta ${day(p.valid_until)}</small>
   </article>`).join(''):'<p class="business-empty">Sin planes emitidos.</p>'}
  </div>
 </aside>
</div>`;
}
