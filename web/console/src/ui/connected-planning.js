import {WOD_FORMATS,summaryHTML} from '../core/structured-prescription.js';

// Presentation-only builder; controller owns the draft state and publishes via
// the authenticated RPC (no mock plans or writes to athlete workout history).
export function renderProfessionalPlanning({orgId,role,sessions=[],clients=[],memberships=[],catalog=[],draft=[],formData={},escapeHTML:h,busy=false}) {
 if(!orgId)return '';
 const editor=['owner','admin','coach'].includes(role),manager=['owner','admin'].includes(role);
 const linked=clients.filter(c=>c.user_id);
 const coaches=memberships.filter(m=>m.organization_id===orgId&&m.role==='coach'&&m.status==='active');
 const options=(rows,fn)=>rows.map(fn).join('');
 const field=(name,value,placeholder='',extra='')=>`<label class="connected-field">${h(name)}<input ${extra} value="${h(value??'')}" placeholder="${h(placeholder)}"></label>`;
 const scope=(scope,field,bi,ei,si)=>`data-plan-scope="${scope}" data-plan-field="${field}" data-bi="${bi}"${ei==null?'':` data-ei="${ei}"`}${si==null?'':` data-si="${si}"`}`;
 const row=(block,i,e,j)=>{
  const list=block.kind==='strength'?'exercises':'movements';
  return `<div class="connected-block-editor" aria-label="Movimiento ${j+1}">
   <div class="connected-panel-header"><strong>${h(j+1+'. '+(e.name||'Nuevo movimiento'))}</strong><button type="button" class="connected-secondary" data-plan-action="remove-entry" data-bi="${i}" data-ei="${j}">Quitar</button></div>
   <div class="connected-form-grid">
    <label class="connected-field">Origen
     <select ${scope('entry','source',i,j)}><option value="catalog" ${e.source==='catalog'?'selected':''}>Catálogo Repera</option><option value="free" ${e.source==='free'?'selected':''}>Ejercicio libre</option></select></label>
    ${e.source==='catalog'? `<label class="connected-field">Buscar / elegir movimiento
     <select ${scope('entry','catalogKey',i,j)}><option value="">Selecciona ejercicio…</option>${options(catalog,x=>`<option value="${h(x.catalogKey)}" ${e.catalogKey===x.catalogKey?'selected':''}>${h(x.name)} · ${h(x.category)}</option>`)}</select></label>`
      :field('Nombre libre',e.name,'Ej. Caminata con saco',scope('entry','name',i,j)+' minlength="2" maxlength="150"')}
   </div>
   ${list==='exercises'?
    `<div class="connected-eyebrow" style="margin:14px 0 6px">Series · repeticiones · carga · RIR</div>
     ${(e.plannedSets||[]).map((s,k)=>`<div class="connected-form-grid" style="grid-template-columns:repeat(4,minmax(0,1fr));margin-bottom:8px">
      ${field('Reps',s.targetReps,'8',scope('set','targetReps',i,j,k)+' type="number" min="1" max="9999"')}
      ${field('Kg',s.targetWeightKg??'','—',scope('set','targetWeightKg',i,j,k)+' type="number" min="0" max="2000" step="0.5"')}
      ${field('RIR',s.targetRir??'','—',scope('set','targetRir',i,j,k)+' type="number" min="0" max="10" step="0.5"')}
      <button type="button" class="connected-secondary" data-plan-action="remove-set" data-bi="${i}" data-ei="${j}" data-si="${k}" style="align-self:end">Quitar serie</button>
     </div>`).join('')}
     <button type="button" class="connected-secondary" data-plan-action="add-set" data-bi="${i}" data-ei="${j}">+ Añadir serie</button>`
    :`<div class="connected-form-grid" style="margin-top:12px">
       ${field('Repeticiones',e.reps??10,'10',scope('entry','reps',i,j)+' type="number" min="1" max="9999"')}
       ${field('Notas / escala',e.notes??'','Opcional',scope('entry','notes',i,j)+' maxlength="500"')}
      </div>`}
  </div>`;
 };
 const block=(b,i)=>`<article class="connected-block-editor">
 <div class="connected-panel-header"><div><span class="connected-eyebrow">Bloque ${i+1} · ${b.kind==='wod'?'WOD':'Fuerza'}</span><h3 style="margin:6px 0">${h(b.title)}</h3></div>
 <button type="button" class="connected-secondary" data-plan-action="remove-block" data-bi="${i}">Eliminar bloque</button></div>
 ${field('Nombre del bloque',b.title,'Ej. Fuerza principal',scope('block','title',i)+' minlength="2" maxlength="120"')}
 ${b.kind==='wod'?`<div class="connected-form-grid">
 <label class="connected-field">Formato WOD<select ${scope('block','wodFormat',i)}>${options(WOD_FORMATS,([v,n])=>`<option value="${h(v)}" ${b.wodFormat===v?'selected':''}>${h(n)}</option>`)}</select></label>
 ${field('Rondas',b.rounds??'','Opcional',scope('block','rounds',i)+' type="number" min="1" max="300"')}
 ${field('Tiempo límite · min',b.timeCapMinutes??'','Opcional',scope('block','timeCapMinutes',i)+' type="number" min="1" max="300"')}
 </div>`:''}
 <div class="connected-eyebrow" style="margin:16px 0 6px">${b.kind==='wod'?'Movimientos del WOD':'Ejercicios y series'}</div>
 ${(b.kind==='wod'?b.movements:b.exercises).map((e,j)=>row(b,i,e,j)).join('')}
 <div class="connected-builder-actions"><button class="connected-secondary" type="button" data-plan-action="add-entry" data-source="catalog" data-bi="${i}">+ Del catálogo</button>
 <button class="connected-secondary" type="button" data-plan-action="add-entry" data-source="free" data-bi="${i}">+ Ejercicio libre</button></div>
 </article>`;
 const published=`<div class="connected-plan-stack">${sessions.length?options(sessions,s=>`<article class="connected-plan">
 <div class="connected-plan-top"><div><span class="connected-eyebrow">${h(s.scheduled_date)} · ${h(clients.find(c=>c.id===s.client_id)?.name||s.client_id.slice(0,8))}</span>
 <h3 style="margin:5px 0">${h(s.title)}</h3></div><span class="connected-pill">${s.status==='scheduled'?'Publicado':'Cancelado'}</span></div>
 ${summaryHTML(s.prescription,s.instructions,h)}</article>`):'<p>El calendario todavía no tiene sesiones publicadas. Crea una planificación completa debajo.</p>'}</div>`;
 const form=editor&&linked.length?`<form data-connected="publish-session" class="connected-plan-editor">
 <div class="connected-form-grid">
 <label class="connected-field">Deportista vinculado<select name="client" data-plan-header="client" required>${options(linked,c=>`<option value="${h(c.id)}" ${formData.client===c.id?'selected':''}>${h(c.name)}</option>`)}</select></label>
 <label class="connected-field">Fecha<input name="date" data-plan-header="date" value="${h(formData.date||'')}" type="date" required></label>
 </div>
 ${field('Título del entreno',formData.title||'','Ej. Fuerza + WOD','name="title" data-plan-header="title" minlength="2" maxlength="120" required')}
 <label class="connected-field">Notas del entrenador<textarea name="instructions" data-plan-header="instructions" maxlength="10000" rows="2" placeholder="Objetivo, material y recomendaciones">${h(formData.instructions||'')}</textarea></label>
 <div class="connected-panel-header" style="margin-top:18px"><div><span class="connected-eyebrow">Programación por bloques</span><h2>Construye el entrenamiento</h2></div><span class="connected-pill">${draft.length} bloque(s)</span></div>
 ${draft.map(block).join('')}
 <div class="connected-builder-actions"><button type="button" class="connected-secondary" data-plan-action="add-block" data-kind="strength">+ Bloque de fuerza</button>
 <button type="button" class="connected-secondary" data-plan-action="add-block" data-kind="wod">+ WOD</button></div>
 <p>Los movimientos del catálogo mantienen la identidad de la app. Los libres solo viven en esta planificación.</p>
 <button class="connected-primary" type="submit" ${busy?'disabled':''} style="width:100%;margin-top:12px">Publicar al Diario del deportista</button></form>`
 :editor?'<p>Antes de programar, invita al deportista y espera a que acepte la vinculación.</p>':'';
 return `<section class="connected-card" style="margin-top:22px"><div class="connected-panel-header">
 <div><span class="connected-eyebrow">Planificación compartida</span><h2>Entrenamientos</h2><p>Una única estructura de bloques, ejercicios, WOD y series en web, Supabase e iOS.</p></div>
 <span class="connected-pill">Sin modificar el historial privado</span></div>
 ${published}
 ${form}
 ${manager&&coaches.length&&linked.length?`<form data-connected="assign-coach" style="margin-top:22px"><h3>Asignar entrenador</h3><div class="connected-form-grid">
 <label class="connected-field">Cliente<select name="client">${options(linked,c=>`<option value="${h(c.id)}">${h(c.name)}</option>`)}</select></label>
 <label class="connected-field">Entrenador<select name="coach">${options(coaches,c=>`<option value="${h(c.user_id)}">${h(c.user_id.slice(0,8))}</option>`)}</select></label>
 </div><button class="connected-secondary" ${busy?'disabled':''}>Asignar</button></form>`:''}
 </section>`;
}
