// Consola de bonos de entrenador personal: precios ≠ pagos; registro presencial ≠ reserva.
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=n=>new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(Number(n||0)/100);
const day=s=>s?new Date(s).toLocaleDateString('es-ES'):'—';
const clientsActive=clients=>clients.filter(c=>c.status==='active'&&c.user_id);
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
export function renderTrainerPassPanel({clients=[],passes=[],offers=[],attendance=[],occurrences=[],seat,
 manager=false,busy=false}){
 const linked=clientsActive(clients),activeOffers=offers.filter(o=>o.is_active);
 const selectablePasses=passes.filter(p=>p.status==='active'&&p.kind==='appointment'
  &&(p.remaining_credits>0||attendance.some(a=>a.pass_id===p.id))
  &&Date.parse(p.valid_until)>Date.now());
 const trainerOcc=occurrences.filter(o=>o.status==='active'&&o.kind==='appointment');
 const offerRows=offers.map(o=>`<article class="connected-org trainer-offer-row"><div>
 <strong>${esc(o.name)}</strong><small>${o.credits} sesiones · ${o.validity_days} días · ${money(o.price_cents)}
 · ${o.is_active?'Publicada':'Desactivada'}</small></div>${manager?`<button type="button" class="connected-secondary" data-action="toggle-pass-offer"
 data-id="${esc(o.id)}" data-active="${o.is_active?'true':'false'}">${o.is_active?'Desactivar':'Activar'}</button>`:''}</article>`).join('');
 return `<div class="trainer-pass-dashboard">
 <section class="connected-card"><div class="business-panel-head"><div><h2>Bonos y tarifas</h2>
 <p>Configura tus servicios, asígnalos a un cliente y registra las sesiones realizadas.
 El precio publicado no implica que Repera haya cobrado ese importe.</p></div></div>
 <div class="trainer-seats"><strong>${seat.used} / ${seat.max===Infinity?'∞':seat.max} clientes vinculados</strong>
 <span>${esc(seat.label)} · ${seat.left===Infinity?'Sin límite de plazas':seat.left+' plazas disponibles'}</span></div>
 <h3>Mis bonos</h3>${offerRows||'<p>No has creado ningún bono todavía.</p>'}
 ${manager?`<details class="trainer-expander"><summary>+ Crear una tarifa o bono</summary>
 <form data-connected="create-pass-offer" class="business-form">
 <label class="connected-field">Nombre<input name="name" minlength="2" maxlength="120" placeholder="Bono de 10 sesiones" required></label>
 <div class="trainer-form-cols">
 <label class="connected-field">Sesiones<input name="credits" type="number" min="1" max="1000" value="10" required></label>
 <label class="connected-field">Validez en días<input name="validityDays" type="number" min="1" max="730" value="90" required></label>
 <label class="connected-field">Precio total (€)<input name="price" type="number" min="0" max="100000" step=".01" required></label></div>
 <input name="kind" type="hidden" value="appointment">
 <button class="connected-primary" ${busy?'disabled':''}>Guardar bono</button></form></details>`:''}
 </section>
 <section class="connected-card"><h2>Asignar bono a un cliente</h2><p>El bono permite descontar sesiones.
 Si el cobro se ha hecho fuera de Repera, regístralo como gestión externa; la app no verificará ese pago.</p>
 ${manager&&linked.length&&activeOffers.length?`<form class="business-form" data-connected="issue-offline-pass">
 <label class="connected-field">Cliente<select name="client" required>${linked.map(c=>`<option value="${esc(c.id)}">${esc(c.name)}</option>`).join('')}</select></label>
 <label class="connected-field">Bono<select name="offer" required>${activeOffers.map(o=>`<option value="${esc(o.id)}">${esc(o.name)} — ${o.credits} sesiones — ${money(o.price_cents)}</option>`).join('')}</select></label>
 <label class="trainer-verify"><input name="confirmed" value="yes" type="checkbox" required>
 Confirmo que la asignación y, cuando corresponda, el cobro se han gestionado fuera de Repera.
 Esta acción no genera un recibo ni acredita un pago en la plataforma.</label>
 <button class="connected-primary" ${busy?'disabled':''}>Asignar bono</button></form>`:
 '<p>Necesitas un cliente vinculado y una tarifa activa para asignar un bono.</p>'}
 </section>
 <section class="connected-card"><h2>Registrar sesión realizada</h2>
 <p>Puedes registrar una sesión en el momento de comenzar, aunque no hubiera entrenamiento planificado.
 Se descuenta un crédito de su bono activo. Si ya existía reserva con crédito descontado, únicamente se registra la asistencia.</p>
 ${manager&&selectablePasses.length?`<form class="business-form" data-connected="trainer-attendance">
 <label class="connected-field">Bono disponible<select name="pass" required>${selectablePasses.map(p=>`<option value="${esc(p.id)}" data-client-id="${esc(p.client_id)}">${esc(clients.find(c=>c.id===p.client_id)?.name||'Atleta')} — ${p.remaining_credits} sesiones disponibles</option>`).join('')}</select></label>
 <label class="connected-field">Cita de agenda (opcional)<select name="occurrence"><option value="">Sin cita previa · sesión realizada ahora</option>${trainerOcc.map(o=>`<option value="${esc(o.id)}">${esc(o.title)} · ${day(o.starts_at)}</option>`).join('')}</select></label>
 <label class="connected-field">Notas de sesión<textarea name="note" rows="2" maxlength="1000" placeholder="Sesión de técnica y fuerza"></textarea></label>
 <button class="connected-primary" ${busy?'disabled':''}>Confirmar sesión realizada</button></form>`:
 '<p>No hay bonos activos utilizables. Asigna uno primero.</p>'}
 <h3>Registro de asistencias</h3>${attendance.length?attendance.slice(0,20).map(a=>`<article class="business-line">
 <strong>${esc(clients.find(c=>c.id===a.client_id)?.name||'Cliente')}</strong><small>${day(a.performed_at)} · ${a.booking_id?'Reserva ya descontada':'1 sesión descontada'} ${a.note?'· '+esc(a.note):''}</small></article>`).join(''):
 '<p>Aún no hay sesiones registradas.</p>'}
 </section>
 <section class="connected-card"><h2>Saldo por deportista</h2>
 ${passes.map(p=>`<div class="business-line"><strong>${esc(clients.find(c=>c.id===p.client_id)?.name||'Cliente')}</strong>
 <small>${p.remaining_credits}/${p.total_credits} sesiones · ${p.issuance_type==='manual_offline'?'Asignación externa':p.issuance_type==='complimentary'?'Cortesía':'Bono'} · hasta ${day(p.valid_until)}</small></div>`).join('')||'<p>Sin bonos emitidos.</p>'}
 </section></div>`;
}
