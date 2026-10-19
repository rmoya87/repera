// Escaped, read-only business services plus manager-only creation/courtesy actions.
// This screen never claims a courtesy pass is paid and never simulates availability.
export function renderServicesPanel({selectedOrg,role,occurrences=[],passes=[],bookings=[],clients=[],memberships=[],busy=false,escapeHTML}) {
 if(!selectedOrg)return '';
 const manager=role==='owner'||role==='admin';
 const linked=clients.filter(c=>!!c.user_id);
 const coaches=memberships.filter(m=>m.organization_id===selectedOrg&&m.status==='active'&&['owner','admin','coach'].includes(m.role));
 const countBookings=(id)=>bookings.filter(b=>b.occurrence_id===id&&b.status==='booked').length;
 const fmtDate=(date)=>{const parsed=new Date(date);return Number.isFinite(parsed.getTime())?parsed.toLocaleString('es-ES',{dateStyle:'medium',timeStyle:'short'}):'Sin fecha';};
 const options=(rows,map)=>rows.map(map).join('');
 const canCreate=manager&&coaches.length>0;
 return `<section class="connected-card" style="margin-top:22px">
 <h2>Clases y citas reales</h2>
 <p>Agenda guardada en Supabase. Los huecos personales tienen aforo 1 y no pueden solaparse con otros servicios del entrenador.</p>
 ${occurrences.length?options(occurrences,o=>`<article class="connected-org"><div><strong>${escapeHTML(o.title)}</strong><small>${escapeHTML(o.kind==='class'?'Clase grupal':'Sesión individual')} · ${escapeHTML(fmtDate(o.starts_at))} · ${escapeHTML(o.status)}</small><small>${escapeHTML(String(countBookings(o.id)))} / ${escapeHTML(String(o.capacity))} reservas confirmadas (solo con permiso de gestión)</small></div></article>`):'<p>Sin clases o citas registradas todavía.</p>'}
 ${canCreate?`<form data-connected="service-occurrence">
 <label class="connected-field">Servicio<select name="kind"><option value="class">Clase grupal</option><option value="appointment">Cita individual (aforo 1)</option></select></label>
 <label class="connected-field">Entrenador<select name="coach">${options(coaches,m=>`<option value="${escapeHTML(m.user_id)}">${escapeHTML(m.user_id.slice(0,8))} (${escapeHTML(m.role)})</option>`)}</select></label>
 <label class="connected-field">Título<input name="title" required minlength="2" maxlength="120"></label>
 <label class="connected-field">Inicio<input name="start" type="datetime-local" required></label>
 <label class="connected-field">Fin<input name="end" type="datetime-local" required></label>
 <label class="connected-field">Aforo (para cita individual: 1)<input name="capacity" type="number" min="1" max="200" value="1" required></label>
 <button class="connected-primary" ${busy?'disabled':''}>Crear horario</button></form>`:''}
 </section><section class="connected-card" style="margin-top:22px">
 <h2>Bonos y sesiones</h2>
 <p>Los saldos se leen de Supabase, separados por clase y cita. Únicamente se pueden emitir bonos <strong>de cortesía</strong> hasta integrar los cobros verificados.</p>
 ${passes.length?options(passes,p=>`<article class="connected-org"><div><strong>${escapeHTML(p.kind==='class'?'Clases':'Citas personales')}</strong><small>${escapeHTML(String(p.remaining_credits))} de ${escapeHTML(String(p.total_credits))} disponibles · ${escapeHTML(p.status)} · vence ${escapeHTML(fmtDate(p.valid_until))}</small><small>Cliente: ${escapeHTML(clients.find(c=>c.id===p.client_id)?.name||p.client_id.slice(0,8))}</small></div></article>`):'<p>Sin bonos sincronizados.</p>'}
 ${manager&&linked.length?`<form data-connected="courtesy-pass"><label class="connected-field">Cliente verificado<select name="client">${options(linked,c=>`<option value="${escapeHTML(c.id)}">${escapeHTML(c.name)}</option>`)}</select></label>
 <label class="connected-field">Tipo de bono<select name="kind"><option value="class">Clases</option><option value="appointment">Sesiones 1:1</option></select></label>
 <label class="connected-field">Sesiones de cortesía<input type="number" name="credits" min="1" max="1000" value="1" required></label>
 <label class="connected-field">Caducidad<input type="date" name="until" required></label>
 <button class="connected-secondary" ${busy?'disabled':''}>Emitir bono sin cobro</button></form>`:manager?'<p>Vincula primero al cliente mediante una invitación aceptada para emitir un bono de cortesía.</p>':''}
 </section>`;
}
