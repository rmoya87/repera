// Chat Business: hilo 1:1 y avisos masivos (todos / clase / grupo / selección).
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const when=t=>t?new Date(t).toLocaleString('es-ES',{dateStyle:'short',timeStyle:'short'}):'';

export function renderClientChatThread({messages=[],clientId='',busy=false}){
 const rows=[...messages].sort((a,b)=>String(a.created_at).localeCompare(String(b.created_at)));
 return `<div class="business-chat-panel">
  <div class="business-chat-thread" role="log" aria-live="polite">
   ${rows.length?rows.map(m=>`<div class="business-chat-bubble ${m.sender_role==='staff'?'is-staff':'is-athlete'}">
     <p>${esc(m.body)}</p>
     <small>${m.sender_role==='staff'?'Tú':'Cliente'} · ${esc(when(m.created_at))}${m.batch_id?' · Aviso':''}</small>
    </div>`).join(''):'<p class="business-empty">Todavía no hay mensajes. Escribe el primero.</p>'}
  </div>
  <form data-connected="chat-send" class="business-chat-compose">
   <input type="hidden" name="client" value="${esc(clientId)}">
   <label class="connected-field sr-only" for="chat-body-${esc(clientId)}">Mensaje</label>
   <textarea id="chat-body-${esc(clientId)}" name="body" rows="2" maxlength="2000" required placeholder="Escribe un mensaje…"></textarea>
   <button type="submit" class="connected-primary" ${busy?'disabled':''}>Enviar</button>
  </form>
 </div>`;
}

export function renderBroadcastPanel({clients=[],occurrences=[],groups=[],manager=false,busy=false}){
 if(!manager)return '';
 const active=clients.filter(c=>c.status==='active'&&c.user_id&&!c.account_deleted_at);
 const upcoming=occurrences.filter(o=>o.status==='active').slice(0,40);
 return `<section class="connected-card business-broadcast">
  <div class="business-panel-head"><div><h2>Aviso a clientes</h2>
   <p>Mensaje masivo a todos, a una clase, a un grupo o a una selección. No es un email.</p></div></div>
  <form data-connected="chat-broadcast" class="business-form">
   <label class="connected-field">Destinatarios
    <select name="scope" required>
     <option value="all">Todos los clientes activos vinculados</option>
     <option value="occurrence">Inscritos de una clase o cita</option>
     <option value="group">Miembros de un grupo</option>
     <option value="selected">Selección manual</option>
    </select>
   </label>
   <label class="connected-field">Clase o cita<select name="occurrence">
    <option value="">—</option>
    ${upcoming.map(o=>`<option value="${esc(o.id)}">${esc(o.title)} · ${esc(when(o.starts_at))}</option>`).join('')}
   </select></label>
   <label class="connected-field">Grupo<select name="group">
    <option value="">—</option>
    ${groups.map(g=>`<option value="${esc(g.id)}">${esc(g.name)}</option>`).join('')}
   </select></label>
   <fieldset class="business-broadcast-pick"><legend>Selección manual</legend>
    <div class="business-group-members">${active.map(c=>`<label><input type="checkbox" name="clients" value="${esc(c.id)}"><span>${esc(c.name)}</span></label>`).join('')||'<p>Sin clientes vinculados.</p>'}
   </div></fieldset>
   <label class="connected-field">Mensaje<textarea name="body" rows="3" maxlength="2000" required placeholder="Recordatorio de horario, aviso de cierre…"></textarea></label>
   <button type="submit" class="connected-primary" ${busy?'disabled':''}>Enviar aviso</button>
  </form>
 </section>`;
}
