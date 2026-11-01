// Planes del gimnasio: catálogo 2×2 + asignados a la derecha. Asignar desde ficha del socio.
import {offerSummary,renderOfferPriceCards} from './trainer-pass-panel.js';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
const PAY={card:'Tarjeta',transfer:'Transferencia',cash:'Efectivo',other:'Otro',complimentary:'Cortesía'};
const provenance=p=>{
 if(p.issuance_type==='complimentary'||p.payment_method==='complimentary')return 'Cortesía (sin cobro)';
 if(p.issuance_type==='manual_offline'){
  const how=PAY[p.payment_method];
  const when=p.paid_at?new Date(p.paid_at).toLocaleDateString('es-ES'):'';
  return how?`Cobro ${how}${when?' · '+when:''}`:'Confirmado por el centro';
 }
 return 'Plan';
};
const assignable=clients=>clients.filter(c=>!c.account_deleted_at&&['active','trial','lead','paused'].includes(c.status));

export function renderAssignOfflinePassForm({clients=[],offers=[],clientId='',manager=false,busy=false,kindFilter=null,emptyOffersHint=''}){
 const pool=assignable(clients);
 const activeOffers=offers.filter(o=>o.is_active&&(!kindFilter||o.kind===kindFilter));
 if(!manager)return '<p class="connected-hint">No tienes permiso para asignar planes.</p>';
 if(!activeOffers.length){
  return `<div class="pt-assign-empty"><p>${esc(emptyOffersHint||'No hay planes activos. Crea uno en Planes.')}</p>
   <button type="button" class="connected-primary" data-action="open-create-plan-modal">Crear plan</button></div>`;
 }
 if(!pool.length){
  return `<div class="pt-assign-empty"><p>No hay socios. Invita al primero para poder asignar un plan.</p>
   <button type="button" class="connected-primary" data-action="open-invite-modal">Invitar socio</button></div>`;
 }
 const clientOptions=clientId?pool.filter(c=>c.id===clientId):pool;
 if(clientId&&!clientOptions.length){
  return '<p class="connected-hint">Este socio no admite asignación (archivado o cancelado).</p>';
 }
 const today=new Date().toLocaleDateString('sv-SE');
 return `<form class="business-form" data-connected="issue-offline-pass">
  ${clientId?`<input type="hidden" name="client" value="${esc(clientId)}">`:`
  <label class="connected-field">Socio<select name="client" required>${clientOptions.map(c=>`<option value="${esc(c.id)}" ${c.id===clientId?'selected':''}>${esc(c.name)}${c.user_id?'':' · pendiente'}</option>`).join('')}</select></label>`}
  <label class="connected-field">Plan<select name="offer" required>${activeOffers.map(o=>`<option value="${esc(o.id)}" data-price="${o.price_cents}">${esc(o.name)} — ${offerSummary(o)} · ${o.kind==='class'?'Clases':'Citas'}</option>`).join('')}</select></label>
  <div class="trainer-form-cols">
   <label class="connected-field">Forma de pago<select name="paymentMethod" required>
    <option value="cash">Efectivo</option>
    <option value="transfer">Transferencia</option>
    <option value="card">Tarjeta</option>
    <option value="other">Otro</option>
   </select></label>
   <label class="connected-field">Fecha del cobro<input name="paidAt" type="date" value="${esc(today)}" required></label>
   <label class="connected-field">Importe cobrado (€)<input name="paidAmount" type="number" min="0" max="100000" step=".01" placeholder="Precio del plan"></label>
  </div>
  <label class="connected-field">Nota del cobro (opcional)<input name="paymentNote" maxlength="400" placeholder="Bizum, recibo nº…"></label>
  <label class="trainer-verify"><input name="confirmed" value="yes" type="checkbox" required>
   Confirmo que he recibido el pago fuera de Repera (o que es una asignación autorizada). Esta acción no genera factura ni acredita un cobro en la plataforma.</label>
  <button class="connected-primary" ${busy?'disabled':''}>Asignar plan</button>
 </form>`;
}

export function renderGymPassPanel({clients=[],passes=[],offers=[],manager=false}){
 return `<div class="trainer-pass-dashboard pt-plans-layout">
 <section class="connected-card business-subscriptions pt-plans-catalog">
  <div class="business-panel-head pt-plans-head">
   <div><h2>Planes</h2>
    <p>Así los verás tú y tus socios: bono, mensual, ilimitado o franja. El precio no implica cobro en Repera.</p></div>
   ${manager?`<button type="button" class="connected-primary" data-action="open-create-plan-modal">Crear plan</button>`:''}
  </div>
  ${renderOfferPriceCards({offers,manager,peopleLabel:'socios',hideCreateCard:true})}
 </section>
 <aside class="connected-card pt-plans-assigned">
  <h2>Planes asignados</h2>
  <p class="connected-hint">Resumen por socio. Para asignar o cambiar un plan, abre la ficha del socio → Bonos.</p>
  <div class="pt-assigned-grid">
   ${passes.length?passes.map(p=>`<article class="pt-assigned-tile">
    <strong>${esc(clients.find(c=>c.id===p.client_id)?.name||'Socio')}</strong>
    <small>${p.remaining_credits>=9000?'Ilimitado':`${p.remaining_credits}/${p.total_credits}`} · ${esc(provenance(p))}</small>
    <small>Hasta ${day(p.valid_until)}</small>
   </article>`).join(''):'<p class="business-empty">No hay planes asignados todavía.</p>'}
  </div>
 </aside>
</div>`;
}

export function passProvenanceLabel(p){return provenance(p);}
