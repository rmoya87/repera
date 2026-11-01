// Asignación de bonos en gimnasio: cobro externo declarado, nunca pasarela Repera.
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=n=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(n||0)/100);
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
const provenance=p=>{
 if(p.issuance_type==='manual_offline')return 'Confirmado por el centro';
 if(p.issuance_type==='complimentary')return 'Cortesía (sin cobro)';
 return 'Bono';
};

export function renderAssignOfflinePassForm({clients=[],offers=[],clientId='',manager=false,busy=false,kindFilter=null}){
 const linked=clients.filter(c=>c.status==='active'&&c.user_id&&!c.account_deleted_at);
 const activeOffers=offers.filter(o=>o.is_active&&(!kindFilter||o.kind===kindFilter));
 if(!manager)return '<p class="connected-hint">No tienes permiso para asignar bonos.</p>';
 if(!linked.length||!activeOffers.length){
  return '<p class="connected-hint">Necesitas un socio vinculado y una tarifa activa para asignar un bono.</p>';
 }
 const clientOptions=(clientId?linked.filter(c=>c.id===clientId):linked);
 return `<form class="business-form" data-connected="issue-offline-pass">
  <label class="connected-field">Cliente<select name="client" required ${clientId?'':' '}>${clientOptions.map(c=>`<option value="${esc(c.id)}" ${c.id===clientId?'selected':''}>${esc(c.name)}</option>`).join('')}</select></label>
  <label class="connected-field">Producto<select name="offer" required>${activeOffers.map(o=>`<option value="${esc(o.id)}">${esc(o.name)} — ${o.credits} sesiones — ${money(o.price_cents)} · ${o.kind==='class'?'Clases':'Citas'}</option>`).join('')}</select></label>
  <label class="trainer-verify"><input name="confirmed" value="yes" type="checkbox" required>
   Confirmo que he recibido el pago fuera de Repera (o que es una asignación autorizada). Esta acción no genera factura ni acredita un cobro en la plataforma.</label>
  <button class="connected-primary" ${busy?'disabled':''}>Asignar bono</button>
 </form>`;
}

export function renderGymPassPanel({clients=[],passes=[],offers=[],manager=false,busy=false}){
 const offerRows=offers.map(o=>`<article class="connected-org trainer-offer-row"><div>
  <strong>${esc(o.name)}</strong><small>${o.kind==='class'?'Clases':'Citas'} · ${o.credits} sesiones · ${o.validity_days} días · ${money(o.price_cents)}
  · ${o.is_active?'Publicada':'Desactivada'}</small></div>
  ${manager?`<button type="button" class="connected-secondary" data-action="toggle-pass-offer"
   data-id="${esc(o.id)}" data-active="${o.is_active?'true':'false'}">${o.is_active?'Desactivar':'Activar'}</button>`:''}</article>`).join('');
 return `<div class="trainer-pass-dashboard">
 <section class="connected-card"><div class="business-panel-head"><div><h2>Productos y bonos</h2>
  <p>Publica tarifas y asígnalas tras cobrar fuera de Repera. El precio no implica cobro en la plataforma.</p></div></div>
  <h3>Catálogo</h3>${offerRows||'<p class="business-empty">Todavía no hay tarifas. Crea la primera para poder asignar bonos.</p>'}
  ${manager?`<details class="trainer-expander"><summary>+ Crear tarifa</summary>
  <form data-connected="create-pass-offer" class="business-form">
   <label class="connected-field">Nombre<input name="name" minlength="2" maxlength="120" placeholder="Bono 10 clases" required></label>
   <div class="trainer-form-cols">
   <label class="connected-field">Tipo<select name="kind"><option value="class">Clases</option><option value="appointment">Citas 1:1</option></select></label>
   <label class="connected-field">Sesiones<input name="credits" type="number" min="1" max="1000" value="10" required></label>
   <label class="connected-field">Validez (días)<input name="validityDays" type="number" min="1" max="730" value="90" required></label>
   <label class="connected-field">Precio (€)<input name="price" type="number" min="0" max="100000" step=".01" required></label></div>
   <button class="connected-primary" ${busy?'disabled':''}>Publicar tarifa</button></form></details>`:''}
 </section>
 <section class="connected-card"><h2>Asignar bono a un socio</h2>
  <p>Registra el cobro externo y activa el saldo. Etiqueta: <strong>Confirmado por el centro</strong>.</p>
  ${renderAssignOfflinePassForm({clients,offers,manager,busy})}
 </section>
 <section class="connected-card"><h2>Bonos asignados</h2>
  ${passes.length?passes.map(p=>`<div class="business-line"><strong>${esc(clients.find(c=>c.id===p.client_id)?.name||'Cliente')}</strong>
   <small>${p.remaining_credits}/${p.total_credits} disponibles · ${esc(provenance(p))} · hasta ${day(p.valid_until)}</small></div>`).join(''):
   '<p class="business-empty">No hay bonos asignados. Asigna el primero desde aquí o desde la ficha del socio.</p>'}
 </section></div>`;
}

export function passProvenanceLabel(p){return provenance(p);}
