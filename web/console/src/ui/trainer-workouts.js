// Mis entrenos: biblioteca de plantillas del entrenador personal.
import {
 editorMarkup,emptyPrescription,starterPrescription,visualPrescription,visualSessionMeta,
 setEditorLibraryTemplates,readPrescription,validatePrescription,canonicalPrescription,
} from './workout-editor.js';

const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const blocksLabel=p=>{
 const n=(visualPrescription(p||emptyPrescription()).blocks||[]).length;
 return n?`${n} bloque${n===1?'':'s'}`:'Sin bloques';
};

/**
 * Sección Mis entrenos (CRUD plantillas). templateId selecciona la que se edita.
 */
export function renderTrainerWorkoutsLibrary({templates=[],templateId=null,busy=false,manager=false,audience='trainer'}){
 const selected=templates.find(t=>t.id===templateId)||null;
 const prescription=selected?visualPrescription(selected.prescription):starterPrescription();
 setEditorLibraryTemplates(templates);
 const who=audience==='gym'?'socios':'clientes';
 const list=templates.length?templates.map(t=>`<article class="pt-lib-row ${t.id===templateId?'is-active':''}">
  <div><strong>${esc(t.name)}</strong><small>${esc(t.description||'Plantilla reutilizable')} · ${blocksLabel(t.prescription)}</small></div>
  <div class="pt-lib-row-actions">
   <button type="button" class="connected-secondary" data-action="edit-library-template" data-id="${esc(t.id)}">Editar</button>
   ${manager&&audience==='gym'?`<button type="button" class="connected-primary" data-action="assign-template-to-classes" data-id="${esc(t.id)}">Asignar a clases</button>`:''}
   ${manager?`<button type="button" class="connected-secondary" data-action="delete-library-template" data-id="${esc(t.id)}">Eliminar</button>`:''}
  </div>
 </article>`).join(''):`<p class="business-empty">Crea tu primera plantilla para reutilizarla al programar ${who}.</p>`;

 return `<div class="pt-mis-entrenos">
  <div class="pt-home-toolbar pt-lib-toolbar">
   <h2 class="pt-lib-heading">Tus plantillas <span>${templates.length}</span></h2>
   ${manager?`<button type="button" class="connected-primary" data-action="new-library-template">+ Nueva plantilla</button>`:''}
  </div>
  <div class="pt-lib-layout">
   <section class="connected-card pt-lib-list">${list}</section>
   <section class="connected-card pt-lib-composer">
    ${manager?`<form data-connected="save-workout-template" class="planning-form">
     <div class="planning-form-heading"><h2>${selected?'Editar plantilla':'Nueva plantilla'}</h2>
      ${selected?`<button type="button" class="connected-secondary" data-action="new-library-template">Empezar de cero</button>`:''}</div>
     ${selected?`<input type="hidden" name="template" value="${esc(selected.id)}">`:''}
     <label class="connected-field">Nombre<input name="name" minlength="2" maxlength="120" required value="${esc(selected?.name||'')}" placeholder="Ej. Full Body A"></label>
     <label class="connected-field">Descripción<input name="description" maxlength="1000" value="${esc(selected?.description||'')}" placeholder="Objetivo, material, nivel…"></label>
     ${editorMarkup(prescription,{meta:visualSessionMeta(selected?.prescription||{}),showMeta:true})}
     <div class="planning-submit"><button type="submit" class="connected-primary" ${busy?'disabled':''}>${selected?'Guardar cambios':'Guardar en Mis entrenos'}</button></div>
     <p class="connected-hint">Guardar no asigna el entreno. En gimnasio usa «Asignar a clases» (día / selección). En PT, desde la ficha o la agenda.</p>
    </form>`:'<p class="connected-hint">No tienes permiso para editar la biblioteca.</p>'}
   </section>
  </div>
 </div>`;
}

/** Panel Insertar (plantillas + copiar sesiones) para el composer a pantalla completa. */
export function renderWorkoutInsertPanel({templates=[],sessions=[],clients=[],clientId='',copyClientId='',busy=false}){
 const own=sessions.filter(s=>s.client_id===clientId&&s.status==='scheduled')
  .sort((a,b)=>String(b.scheduled_date).localeCompare(String(a.scheduled_date))).slice(0,12);
 const otherId=copyClientId||'';
 const others=clients.filter(c=>c.id!==clientId&&!c.account_deleted_at);
 const otherSessions=otherId?sessions.filter(s=>s.client_id===otherId&&s.status==='scheduled')
  .sort((a,b)=>String(b.scheduled_date).localeCompare(String(a.scheduled_date))).slice(0,12):[];
 const tpl=templates.length?templates.map(t=>`<button type="button" class="pt-insert-item" data-action="insert-template" data-id="${esc(t.id)}" ${busy?'disabled':''}>
  <strong>${esc(t.name)}</strong><small>${blocksLabel(t.prescription)} · añadir bloques</small></button>`).join('')
  :'<p class="connected-hint">Aún no hay plantillas. Créalas en Mis entrenos.</p>';
 const ownList=own.length?own.map(s=>`<button type="button" class="pt-insert-item" data-action="copy-session" data-id="${esc(s.id)}" ${busy?'disabled':''}>
  <strong>${esc(s.title)}</strong><small>${esc(s.scheduled_date)} · ${blocksLabel(s.prescription)}</small></button>`).join('')
  :'<p class="connected-hint">Este cliente aún no tiene sesiones publicadas.</p>';
 const otherList=!otherId?'<p class="connected-hint">Elige un cliente para ver sus entrenos.</p>'
  :(otherSessions.length?otherSessions.map(s=>`<button type="button" class="pt-insert-item" data-action="copy-session" data-id="${esc(s.id)}" ${busy?'disabled':''}>
  <strong>${esc(s.title)}</strong><small>${esc(s.scheduled_date)} · ${blocksLabel(s.prescription)}</small></button>`).join('')
  :'<p class="connected-hint">Sin sesiones publicadas para ese cliente.</p>');

 return `<aside class="pt-insert-panel" aria-label="Insertar o copiar entrenos">
  <h3>Insertar</h3>
  <details class="pt-insert-group" open><summary>Mis entrenos</summary><div class="pt-insert-list">${tpl}</div></details>
  <details class="pt-insert-group" open><summary>De este cliente</summary><div class="pt-insert-list">${ownList}</div></details>
  <details class="pt-insert-group"><summary>De otro cliente</summary>
   <label class="connected-field">Cliente<select data-action="copy-browse-client">
    <option value="">Selecciona…</option>
    ${others.map(c=>`<option value="${esc(c.id)}" ${c.id===otherId?'selected':''}>${esc(c.name)}</option>`).join('')}
   </select></label>
   <div class="pt-insert-list">${otherList}</div>
  </details>
  <p class="connected-hint">Se copian los bloques al editor actual. Puedes adaptarlos antes de publicar. El origen no se modifica.</p>
 </aside>`;
}

export function mergePrescriptionBlocks(base,extra){
 const a=visualPrescription(base||emptyPrescription());
 const b=visualPrescription(extra||emptyPrescription());
 return {version:1,blocks:[...(a.blocks||[]),...(b.blocks||[])].slice(0,24)};
}

export {readPrescription,validatePrescription,canonicalPrescription,visualPrescription,emptyPrescription};
