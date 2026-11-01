// Facturación operativa (cobros externos declarados). No es pasarela Repera.
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=n=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(n||0)/100);
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
export const PAYMENT_LABELS={card:'Tarjeta',transfer:'Transferencia',cash:'Efectivo',other:'Otro',complimentary:'Cortesía'};

export function passPaidCents(pass,offers=[]){
 if(Number.isFinite(pass?.paid_amount_cents))return Number(pass.paid_amount_cents);
 if(pass?.issuance_type==='complimentary'||pass?.payment_method==='complimentary')return 0;
 const offer=offers.find(o=>o.id===pass?.offer_id);
 return Number(offer?.price_cents||0);
}

export function remainingValueCents(pass,offers=[]){
 const paid=passPaidCents(pass,offers);
 if(!paid||!pass?.total_credits||pass.total_credits>=9000)return 0;
 const rem=Math.max(0,Number(pass.remaining_credits||0));
 return Math.round(paid*(rem/pass.total_credits));
}

export function buildBillingSummary({clients=[],passes=[],offers=[],attendance=[]}){
 const charged=passes.filter(p=>p.issuance_type==='manual_offline'||(p.payment_method&&p.payment_method!=='complimentary'));
 const courtesy=passes.filter(p=>p.issuance_type==='complimentary'||p.payment_method==='complimentary');
 const totalBilled=charged.reduce((s,p)=>s+passPaidCents(p,offers),0);
 const byMethod={card:0,transfer:0,cash:0,other:0};
 for(const p of charged){
  const m=p.payment_method&&byMethod[p.payment_method]!=null?p.payment_method:'other';
  byMethod[m]+=passPaidCents(p,offers);
 }
 const perClient=clients.filter(c=>!c.account_deleted_at).map(c=>{
  const own=passes.filter(p=>p.client_id===c.id);
  const active=own.filter(p=>p.status==='active'&&Date.parse(p.valid_until)>Date.now());
  const billed=own.filter(p=>p.issuance_type==='manual_offline').reduce((s,p)=>s+passPaidCents(p,offers),0);
  const remainingCredits=active.reduce((s,p)=>s+(p.remaining_credits>=9000?0:Math.max(0,p.remaining_credits||0)),0);
  const remainingValue=active.reduce((s,p)=>s+remainingValueCents(p,offers),0);
  const sessions=attendance.filter(a=>a.client_id===c.id).length;
  return {client:c,billed,remainingCredits,remainingValue,activeCount:active.length,sessions,own};
 }).filter(r=>r.own.length||r.sessions).sort((a,b)=>b.billed-a.billed);

 const recent=charged.slice().sort((a,b)=>String(b.paid_at||b.created_at||'').localeCompare(String(a.paid_at||a.created_at||''))).slice(0,24);

 return {totalBilled,byMethod,courtesyCount:courtesy.length,chargedCount:charged.length,perClient,recent};
}

export function renderBillingDashboard({clients=[],passes=[],offers=[],attendance=[],manager=false}){
 const s=buildBillingSummary({clients,passes,offers,attendance});
 const methods=Object.entries(s.byMethod).filter(([,v])=>v>0)
  .map(([k,v])=>`<div class="pt-bill-stat"><span class="pt-data-label">${esc(PAYMENT_LABELS[k]||k)}</span><strong>${money(v)}</strong></div>`).join('');
 const clientRows=s.perClient.length?s.perClient.map(r=>`<article class="pt-bill-client">
  <div><strong>${esc(r.client.name)}</strong>
   <small>${r.activeCount?`${r.activeCount} bono${r.activeCount===1?'':'s'} activo${r.activeCount===1?'':'s'}`:'Sin bono activo'} · ${r.sessions} sesión${r.sessions===1?'':'es'} registradas</small></div>
  <div class="pt-bill-client-nums">
   <div><span class="pt-data-label">Facturado</span><strong>${money(r.billed)}</strong></div>
   <div><span class="pt-data-label">Saldo sesiones</span><strong>${r.remainingCredits||'—'}</strong></div>
   <div><span class="pt-data-label">Valor restante</span><strong>${money(r.remainingValue)}</strong></div>
  </div>
  ${manager?`<button type="button" class="connected-secondary" data-action="detail-client-passes" data-id="${esc(r.client.id)}">Gestionar</button>`:''}
 </article>`).join(''):'<p class="business-empty">Aún no hay cobros ni bonos asignados.</p>';

 const recentRows=s.recent.length?s.recent.map(p=>{
  const c=clients.find(x=>x.id===p.client_id);
  const offer=offers.find(o=>o.id===p.offer_id);
  return `<article class="business-line"><strong>${esc(c?.name||'Cliente')}</strong>
   <small>${money(passPaidCents(p,offers))} · ${esc(PAYMENT_LABELS[p.payment_method]||'Cobro externo')} · ${day(p.paid_at||p.created_at)} · ${esc(offer?.name||'Bono')}</small></article>`;
 }).join(''):'<p class="business-empty">Sin movimientos de cobro.</p>';

 return `<div class="pt-billing-dashboard">
  <section class="connected-card">
   <div class="business-panel-head"><div><h2>Facturación</h2>
    <p>Totales de cobros externos que has registrado al asignar bonos. Repera no cobra ni factura por ti.</p></div></div>
   <div class="pt-bill-hero">
    <div class="pt-bill-stat is-hero"><span class="pt-data-label">Facturado en total</span><strong>${money(s.totalBilled)}</strong></div>
    <div class="pt-bill-stat"><span class="pt-data-label">Bonos de pago</span><strong>${s.chargedCount}</strong></div>
    <div class="pt-bill-stat"><span class="pt-data-label">Cortesías</span><strong>${s.courtesyCount}</strong></div>
   </div>
   ${methods?`<div class="pt-bill-methods">${methods}</div>`:''}
  </section>
  <section class="connected-card">
   <h2>Por cliente · saldo restante</h2>
   <div class="pt-bill-client-list">${clientRows}</div>
  </section>
  <section class="connected-card">
   <h2>Últimos cobros registrados</h2>
   ${recentRows}
  </section>
 </div>`;
}
