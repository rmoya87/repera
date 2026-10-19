// Read-only date-assigned plans and secure manager forms. No athlete history is stored here.
export function renderProfessionalPlanning({orgId,role,sessions=[],clients=[],memberships=[],escapeHTML,busy=false}) {
 if(!orgId)return '';
 const manager=role==='owner'||role==='admin';
 const linked=clients.filter(c=>c.user_id);
 const coaches=memberships.filter(m=>m.organization_id===orgId&&m.role==='coach'&&m.status==='active');
 const options=(rows,fn)=>rows.map(fn).join('');
 return `<section class="connected-card" style="margin-top:22px"><h2>Planificación profesional publicada</h2>
 <p>El deportista vinculado recibirá la sesión en Diario e Inicio. Sus resultados e historial privados nunca se publican aquí.</p>
 ${sessions.length?options(sessions,s=>`<article class="connected-org"><div><strong>${escapeHTML(s.title)}</strong><small>${escapeHTML(s.scheduled_date)} · ${escapeHTML(s.status)} · ${escapeHTML(clients.find(c=>c.id===s.client_id)?.name||s.client_id.slice(0,8))}</small><small>${escapeHTML(s.instructions||'Sin instrucciones')}</small></div></article>`):'<p>Sin sesiones profesionales publicadas.</p>'}
 ${manager&&linked.length?`<form data-connected="publish-session">
 <label class="connected-field">Cliente vinculado<select name="client">${options(linked,c=>`<option value="${escapeHTML(c.id)}">${escapeHTML(c.name)}</option>`)}</select></label>
 <label class="connected-field">Fecha<input type="date" name="date" required></label>
 <label class="connected-field">Título<input name="title" minlength="2" maxlength="120" required></label>
 <label class="connected-field">Instrucciones<textarea name="instructions" rows="4" maxlength="10000" placeholder="Ejercicios, series, repeticiones y notas del entrenador"></textarea></label>
 <button class="connected-primary" ${busy?'disabled':''}>Publicar entrenamiento</button></form>
 ${coaches.length?`<form data-connected="assign-coach"><label class="connected-field">Cliente<select name="client">${options(linked,c=>`<option value="${escapeHTML(c.id)}">${escapeHTML(c.name)}</option>`)}</select></label><label class="connected-field">Entrenador<select name="coach">${options(coaches,c=>`<option value="${escapeHTML(c.user_id)}">${escapeHTML(c.user_id.slice(0,8))}</option>`)}</select></label><button class="connected-secondary" ${busy?'disabled':''}>Asignar entrenador</button></form>`:''}`:
 manager?'<p>Antes de publicar, invita al deportista para que acepte y vincule su cuenta.</p>':''}
 </section>`;
}
