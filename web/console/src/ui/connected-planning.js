import {editorMarkup,emptyPrescription,visualPrescription} from './workout-editor.js';
import {renderMainProfessionalPlanning} from './connected-planning-main.js';
const dateToday=()=>new Date().toLocaleDateString('sv-SE');
export function renderProfessionalPlanning(props) {
 if(Object.prototype.hasOwnProperty.call(props,'draft'))return renderMainProfessionalPlanning(props);
 const {orgId,role,sessions=[],templates=[],clients=[],memberships=[],escapeHTML,busy=false,templateId=null,sessionId=null,clientId=null,preferredDate='',embedded=false,bulkOnly=false}=props;
 if(!orgId)return '';
 const canEdit=['owner','admin','coach'].includes(role),manager=['owner','admin'].includes(role);
 const linked=clients.filter(c=>c.user_id&&c.status==='active');
 const allowedClients=embedded?linked.filter(c=>c.id===clientId):linked;
 const coaches=memberships.filter(m=>m.organization_id===orgId&&m.role==='coach'&&m.status==='active');
 const options=(rows,fn)=>rows.map(fn).join('');
 const currentSession=sessions.find(s=>s.id===sessionId&&(!embedded||s.client_id===clientId)),selectedTemplate=templates.find(t=>t.id===templateId);
 const prescription=currentSession?.prescription||selectedTemplate?.prescription||emptyPrescription();
 const sessionTitle=currentSession?.title||selectedTemplate?.name||'';
 const sessionDay=currentSession?.scheduled_date||preferredDate||dateToday();
 const sessionTime=Number.isInteger(currentSession?.scheduled_time_minutes)
  ?String(Math.floor(currentSession.scheduled_time_minutes/60)).padStart(2,'0')+':'+String(currentSession.scheduled_time_minutes%60).padStart(2,'0'):'';
 const recipeSummary=s=>{
  const blocks=s.prescription?.blocks||[];
  return `<div class="recipe-summary">${blocks.length?blocks.map(b=>`<span class="recipe-tag">${escapeHTML(b.title||b.kind)} · ${((b.exercises||[]).length+(b.movements||[]).length)} ejercicios</span>`).join(''):'<span class="recipe-tag">Solo instrucciones</span>'}</div>`;
 };
 const bulkPlan=canEdit?`<section class="business-bulk-builder">
 <div class="business-bulk-head"><span class="business-bulk-tag">PLANIFICACIÓN RÁPIDA</span><h3>Programa una sesión para varios días o deportistas</h3>
 <p>Elige una plantilla, las personas y el calendario. Publica todo de una sola vez, sin crear sesiones una a una.</p></div>
 ${templates.length&&linked.length?`<form data-connected="bulk-training" class="business-bulk-form">
 <div class="business-bulk-steps">
 <fieldset class="business-bulk-step"><legend><span>1</span> Entrenamiento</legend>
 <label class="connected-field">Plantilla de Repera<select name="template" required>
 <option value="">Selecciona la plantilla...</option>
 ${options(templates,t=>`<option value="${escapeHTML(t.id)}">${escapeHTML(t.name)} · ${(t.prescription?.blocks||[]).length} bloques</option>`)}
 </select></label>
 <p class="connected-hint">Se copia la estructura de bloques, ejercicios y series de la plantilla.</p></fieldset>
 <fieldset class="business-bulk-step"><legend><span>2</span> Deportistas</legend>
 <div class="business-bulk-select-heading"><strong data-bulk-count>0 deportistas</strong>
 <button class="connected-secondary" type="button" data-action="bulk-select-all">Seleccionar todos</button></div>
 <div class="business-bulk-athletes">${linked.map(c=>`<label class="business-bulk-athlete">
 <input type="checkbox" name="clients" value="${escapeHTML(c.id)}" ${bulkOnly&&c.id===clientId?'checked':''}>
 <span class="business-avatar">${escapeHTML(c.name.split(/\s+/).slice(0,2).map(x=>x[0]).join('').toUpperCase())}</span>
 <span><strong>${escapeHTML(c.name)}</strong><small>${escapeHTML(c.email||'')}</small></span></label>`).join('')}</div>
 </fieldset>
 <fieldset class="business-bulk-step"><legend><span>3</span> Fechas</legend>
 <label class="connected-field">Programar<select data-bulk-range>
 <option value="day">Un día</option><option value="week">Una semana</option>
 <option value="range">Un rango de fechas</option></select></label>
 <div class="business-bulk-dates"><label class="connected-field">Desde<input type="date" name="start" required min="${dateToday()}" value="${dateToday()}"></label>
 <label class="connected-field">Hasta<input type="date" name="end" required min="${dateToday()}" value="${dateToday()}"></label></div>
 <div class="business-bulk-weekdays" aria-label="Días de la semana">
 ${['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'].map((name,i)=>`<label><input type="checkbox" name="weekdays" value="${i+1}" checked><span>${name.slice(0,2)}</span></label>`).join('')}
 </div><p class="connected-hint">La selección aplica a cada semana del rango. Máximo 8 semanas y 120 entrenamientos por publicación.</p>
 </fieldset></div>
 <div class="business-bulk-submit"><div class="business-bulk-publish-note">
 <strong data-bulk-preview aria-live="polite">Selecciona plantilla, atletas y fechas</strong>
 <small>Las sesiones ya publicadas con esta plantilla no se duplicarán. Límite: 120 por publicación.</small></div>
 <button type="submit" class="connected-primary" data-bulk-submit disabled>Publicar planificación</button></div>
 </form>`:`<div class="business-bulk-empty">
 ${!templates.length?'Guarda una plantilla con sus bloques antes de planificar varios días.':'Necesitas al menos un deportista vinculado que haya aceptado la solicitud o invitación.'}</div>`}
 </section>`:'';
 if(bulkOnly)return `<div class="business-bulk-dialog-content">${bulkPlan}</div>`;
 return `<section class="connected-card planning-workspace ${embedded?'business-client-editor':''}" ${embedded?'id="client-workout-editor"':'data-workspace-section="planning"'}>
 <div class="planning-title"><div><span class="connected-tag">PROGRAMACIÓN</span><h2>${embedded?'Entrenamiento individual':'Entrenamientos y plantillas'}</h2>${embedded?'<p>Prepara o modifica el entrenamiento del cliente seleccionado.</p>':''}</div></div>
 ${embedded?'':bulkPlan}
 <div class="planning-split ${embedded?'planning-embedded':''}">${embedded?'':`<div class="planning-collection"><h3>Biblioteca de plantillas <span>${templates.length}</span></h3>
 ${templates.length?options(templates,t=>`<article class="planning-list-row"><div><strong>${escapeHTML(t.name)}</strong><small>${escapeHTML(t.description||'Plantilla reutilizable')}</small>${recipeSummary(t)}</div>${canEdit?`<button type="button" class="connected-secondary" data-action="use-template" data-id="${escapeHTML(t.id)}">Utilizar / editar</button>`:''}</article>`):'<p class="connected-empty">Todavía no hay plantillas. Configura los bloques y guárdalos para repetir entrenos sin empezar de cero.</p>'}
 <h3>Sesiones de clientes <span>${sessions.length}</span></h3>
 ${sessions.length?options(sessions,s=>`<article class="planning-list-row"><div><strong>${escapeHTML(s.title)}</strong><small>${escapeHTML(s.scheduled_date)}${Number.isInteger(s.scheduled_time_minutes)?' · '+String(Math.floor(s.scheduled_time_minutes/60)).padStart(2,'0')+':'+String(s.scheduled_time_minutes%60).padStart(2,'0'):''} · ${escapeHTML(clients.find(c=>c.id===s.client_id)?.name||'Deportista')} · ${escapeHTML(s.status)}</small>${recipeSummary(s)}</div>${canEdit&&s.status==='scheduled'&&s.scheduled_date>=dateToday()?`<button type="button" class="connected-secondary" data-action="edit-session" data-id="${escapeHTML(s.id)}">Modificar</button>`:''}</article>`):'<p class="connected-empty">Aún no hay entrenamientos publicados.</p>'}
 </div>`}<div class="planning-composer">
 ${embedded&&templates.length?`<div class="planning-quick-templates"><strong>Usar plantilla guardada (opcional)</strong><div class="heading-actions">${templates.map(t=>`<button type="button" class="connected-secondary" data-action="use-template" data-id="${escapeHTML(t.id)}">${escapeHTML(t.name)}</button>`).join('')}</div></div>`:''}
 ${canEdit&&allowedClients.length?`<form data-connected="publish-session" class="planning-form">
 <div class="planning-form-heading"><h3>${currentSession?'Editar entreno individual':selectedTemplate?'Usar una plantilla':'Preparar entrenamiento'}</h3>${currentSession||selectedTemplate?'<button type="button" data-action="new-workout" class="connected-secondary">Empezar de cero</button>':''}</div>
 <div class="planning-form-row"><label class="connected-field">Deportista<select name="client" ${currentSession?'disabled':''}>${options(allowedClients,c=>`<option value="${escapeHTML(c.id)}" ${c.id===(currentSession?.client_id||clientId)?'selected':''}>${escapeHTML(c.name)}</option>`)}</select></label>
 <label class="connected-field">Fecha<input type="date" name="date" value="${escapeHTML(sessionDay)}" ${currentSession?'':`min="${dateToday()}"`} required></label><label class="connected-field">Hora (opcional)<input type="time" name="time" value="${escapeHTML(sessionTime)}"></label></div>
 <label class="connected-field">Título de la sesión<input name="title" minlength="2" maxlength="120" value="${escapeHTML(sessionTitle)}" required placeholder="Ej. Fuerza + AMRAP 12'"></label>
 ${editorMarkup(visualPrescription(prescription))}
 <label class="connected-field">Indicaciones para el deportista<textarea name="instructions" rows="3" maxlength="10000" placeholder="Objetivo y recomendaciones">${escapeHTML(currentSession?.instructions||'')}</textarea></label>
 <div class="planning-template-save"><label class="connected-field">Nombre para guardar como plantilla<input name="templateName" minlength="2" maxlength="120" value="${escapeHTML(selectedTemplate?.name||sessionTitle||'')}" placeholder="Ej. Full Body A"></label>
 <label class="connected-field">Descripción de la plantilla<input name="templateDescription" maxlength="1000" value="${escapeHTML(selectedTemplate?.description||'')}" placeholder="Objetivos, equipo, nivel…"></label></div>
 <div class="planning-submit"><button type="submit" class="connected-secondary" data-intent="template" ${busy?'disabled':''}>${selectedTemplate?'Actualizar plantilla':'Guardar plantilla'}</button><button type="submit" class="connected-primary" data-intent="publish" ${busy?'disabled':''}>${currentSession?'Guardar cambios del cliente':'Publicar para deportista'}</button></div>
 <p class="connected-hint">Guardar plantilla no asigna ningún entrenamiento. Publicar guarda la versión actual solo para el deportista seleccionado.</p>
 </form>`:canEdit?'<p>Invita al deportista y espera a que acepte y vincule su cuenta para poder publicarle entrenamientos.</p>':'<p>La gestión de entrenamientos requiere permisos de entrenador o administración.</p>'}
 </div></div>
 ${!embedded&&manager&&coaches.length&&linked.length?`<form data-connected="assign-coach" class="coach-assignment"><label class="connected-field">Deportista<select name="client">${options(linked,c=>`<option value="${escapeHTML(c.id)}">${escapeHTML(c.name)}</option>`)}</select></label><label class="connected-field">Entrenador<select name="coach">${options(coaches,c=>`<option value="${escapeHTML(c.user_id)}">${escapeHTML(c.user_id.slice(0,8))}</option>`)}</select></label><button class="connected-secondary" ${busy?'disabled':''}>Asignar entrenador</button></form>`:''}
 </section>`;
}