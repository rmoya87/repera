import {APP_CATALOG} from './exercise-catalog.js';
// Editor de prescripciones Repera Business. Formato serializable compartido con iOS/Android.
// App solo entiende bloques strength|wod; descansos = movimientos isRest dentro de WOD
// (o bloque WOD «Descanso»), nunca dentro de strength.
const CURATED = [
 ['sentadilla','Sentadilla / Back Squat','Pierna','art_sentadilla'],
 ['sentadilla-frontal','Sentadilla frontal / Front Squat','Pierna','art_sentadilla_frontal'],
 ['peso-muerto','Peso muerto / Deadlift','Pierna','art_peso_muerto'],
 ['peso-muerto-rumano','Peso muerto rumano / RDL','Pierna','art_rdl'],
 ['zancadas','Zancadas / Lunges','Pierna','art_zancadas'],
 ['bulgara','Sentadilla búlgara / Bulgarian Split Squat','Pierna','art_bulgara'],
 ['hip-thrust','Hip Thrust','Pierna','art_hip_thrust'],
 ['prensa','Prensa de piernas / Leg Press','Pierna','art_prensa'],
 ['press-banca','Press banca / Bench Press','Pecho','art_press_banca'],
 ['press-inclinado','Press inclinado / Incline Press','Pecho','art_press_inclinado'],
 ['press-militar','Press militar / Overhead Press','Hombro','art_press_militar'],
 ['press-mancuernas','Press con mancuernas / Dumbbell Press','Pecho','art_press_mancuernas'],
 ['dominadas','Dominadas / Pull-ups','Espalda','art_dominadas'],
 ['remo-barra','Remo con barra / Barbell Row','Espalda','art_remo_barra'],
 ['remo-mancuerna','Remo con mancuerna / Dumbbell Row','Espalda','art_remo_mancuerna'],
 ['jalon','Jalón al pecho / Lat Pulldown','Espalda','art_jalon'],
 ['curl-biceps','Curl de bíceps / Biceps Curl','Brazo','art_curl_mancuernas'],
 ['fondos','Fondos / Dips','Pecho','art_fondos'],
 ['plancha','Plancha / Plank','Core','art_plancha'],
 ['crunch','Crunch abdominal','Core','art_crunch'],
 ['air-squat','Air Squat','CrossFit','art_gy_air_squat'],
 ['burpee','Burpees','CrossFit','art_cf_burpee'],
 ['thruster','Thruster','CrossFit','art_cf_thruster'],
 ['wall-ball','Wall Balls','CrossFit','art_cf_wall_ball'],
 ['box-jump','Box Jumps','CrossFit','art_cf_box_jump'],
 ['double-under','Double Unders / Saltos dobles','CrossFit','art_cf_du'],
 ['toes-to-bar','Toes to Bar / Pies a barra','CrossFit','art_cf_ttb'],
 ['clean','Clean / Cargada','Halterofilia','art_cf_cargada'],
 ['snatch','Snatch / Arrancada','Halterofilia','art_cf_arrancada'],
 ['push-press','Push Press','Halterofilia','art_cf_push_press'],
 ['kb-swing','Kettlebell Swing','CrossFit','art_cf_kb_swing'],
 ['db-snatch','Dumbbell Snatch','CrossFit','art_cf_db_snatch'],
 ['rowing','Remo ergómetro / Row','Cardio','art_remo_erg'],
 ['bike','Bicicleta / Bike','Cardio','art_bici'],
 ['running','Carrera / Run','Cardio','art_cardio'],
 ['sit-ups','Sit-ups / Abdominales','Core','art_cf_situp'],
 ['walking-lunges','Walking Lunges / Zancadas caminando','CrossFit','art_cf_walk_lunge'],
 ['hspu','Handstand Push-ups','Gimnasia','art_cf_hspu'],
 ['muscle-up','Muscle-ups','Gimnasia','art_cf_mu_rings']
].map(([id,name,group,art])=>({id,name,group,art}));
export const MOVEMENTS=[...CURATED,...APP_CATALOG.filter(item=>!CURATED.some(base=>base.art===item.art&&base.name.toLowerCase().startsWith(item.name.toLowerCase())))];
const TYPES={strength:'Fuerza',wod:'WOD / Metcon',warmup:'Calentamiento',accessory:'Accesorios'};
// Formatos alineados con WODFormat de ReperaDomain (apps).
const FORMATS={
 sets:'Series (fuerza)',
 amrap:'AMRAP',
 emom:'EMOM / Every',
 tabata:'Tabata',
 rft:'RFT / For Time',
 fortime:'For Time',
 circuit:'Circuito',
 chipper:'Chipper',
 every:'Every / Intervalos'
};
const escapeHTML=value=>String(value??'').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[ch]));
const integer=(v,def=0)=>Number.isFinite(Number(v))?Math.round(Number(v)):def;
export const EXERCISE_ART_BASE='../assets/exercises';
export function exerciseArtUrl(art){
 return art?`${EXERCISE_ART_BASE}/${encodeURIComponent(art)}.jpg`:'';
}
export function exerciseThumbHTML(m,{size=''}={}){
 const cls=size?`exercise-thumb ${size}`:'exercise-thumb';
 if(!m?.art)return `<span class="${cls} exercise-thumb-empty" aria-hidden="true">＋</span>`;
 return `<img class="${cls}" loading="lazy" decoding="async" src="${exerciseArtUrl(m.art)}" alt="" onerror="this.classList.add('is-broken');this.removeAttribute('src')">`;
}
const thumb=m=>exerciseThumbHTML(m);

/** Plantillas Mis entrenos disponibles en el picker del bloque. */
let libraryTemplates=[];
export function setEditorLibraryTemplates(rows=[]){libraryTemplates=Array.isArray(rows)?rows:[];}
let editorUI={pickerBlock:-1,panel:null};
export function emptyPrescription(){return {version:1,blocks:[]};}
/** Bloque inicial vacío con biblioteca lista (Mis entrenos / programar cliente). */
export function starterPrescription(){
 return {version:1,blocks:[{kind:'strength',format:'sets',title:'Fuerza',rounds:1,timeCap:0,exercises:[]}]};
}
/** Abre la biblioteca dentro del primer bloque (al entrar a «Añadir entreno»). */
export function openStarterLibrary(){editorUI={pickerBlock:0,panel:'library'};}
export function resetEditorPanels(){editorUI={pickerBlock:-1,panel:null};}

export function isRestMovement(x){
 return x?.itemKind==='rest'||String(x?.id||'')==='rest'||/^descanso$/i.test(String(x?.name||'').trim())||x?.isRest===true;
}
function restItem(seconds=60){
 return {id:'rest',name:'Descanso',itemKind:'rest',isRest:true,sets:1,reps:0,rir:0,weight:0,duration:Math.max(5,seconds||60),notes:''};
}
function timerWorkItem(){
 return {id:'custom',name:'Intervalo',sets:1,reps:1,rir:0,weight:0,duration:0,notes:'Temporizador'};
}

export function validatePrescription(value){
 if(!value||value.version!==1||!Array.isArray(value.blocks)||value.blocks.length>24)throw Error('Estructura de entrenamiento no válida');
 const blocks=value.blocks.map(b=>{
  if(!TYPES[b.kind]||!FORMATS[b.format]||!Array.isArray(b.exercises)||b.exercises.length>40)throw Error('Bloque de entrenamiento no válido');
  const exercises=b.exercises.map(x=>{
   const label=String(x.name||'').trim().slice(0,120);
   if(!label)throw Error('Cada ejercicio debe tener un nombre');
   const sets=integer(x.sets,3),reps=integer(x.reps,8),rir=integer(x.rir,2),weight=Number(x.weight||0),duration=integer(x.duration,0);
   if(sets<1||sets>50||reps<0||reps>1000||rir<0||rir>10||!Number.isFinite(weight)||weight<0||weight>1000||duration<0||duration>3600)throw Error('Revisa series, repeticiones, RIR, peso o duración');
   const row={id:String(x.id||'custom').slice(0,80),name:label,sets,reps,rir,weight,duration,notes:String(x.notes||'').slice(0,400)};
   if(isRestMovement(x)){row.id='rest';row.itemKind='rest';row.isRest=true;}
   return row;
  });
  if(!exercises.length)throw Error('Añade al menos un ejercicio o descanso a cada bloque');
  return {kind:b.kind,format:b.format,title:String(b.title||TYPES[b.kind]).slice(0,120),rounds:Math.max(1,Math.min(100,integer(b.rounds,1))),timeCap:Math.max(0,Math.min(720,integer(b.timeCap,0))),exercises};
 });
 if(!blocks.length)throw Error('Añade un bloque de fuerza, calentamiento o WOD');
 return {version:1,blocks};
}
function num(value, min, max, label, key, step=1){return `<label class="editor-number"><span>${label}</span><input data-editor-field="${key}" type="number" value="${escapeHTML(value)}" min="${min}" max="${max}" step="${step}"></label>`;}
function select(value,choices,key){return `<select data-editor-field="${key}" aria-label="${key}">${Object.entries(choices).map(([v,t])=>`<option value="${v}" ${v===value?'selected':''}>${t}</option>`).join('')}</select>`;}

function movementMarkup(x,i){
 const known=MOVEMENTS.find(m=>m.id===x.id);
 if(isRestMovement(x)){
  return `<article class="editor-exercise is-rest" data-editor-exercise data-id="rest" data-name="Descanso" data-item-kind="rest"><div class="editor-exercise-head"><span class="exercise-thumb exercise-thumb-empty" aria-hidden="true">⏱</span><div class="exercise-title"><strong>Descanso</strong><small>Pausa (como en la app)</small></div><button type="button" class="editor-icon-button" data-editor-action="remove-exercise" data-exercise="${i}" title="Eliminar descanso" aria-label="Eliminar descanso">×</button></div><div class="editor-values">
 ${num(x.duration??60,5,3600,'Segundos','duration')}
 </div><label class="editor-notes">Notas<input data-editor-field="notes" value="${escapeHTML(x.notes||'')}" maxlength="400" placeholder="Opcional"></label>
 <input type="hidden" data-editor-field="sets" value="1"><input type="hidden" data-editor-field="reps" value="0"><input type="hidden" data-editor-field="rir" value="0"><input type="hidden" data-editor-field="weight" value="0"></article>`;
 }
 return `<article class="editor-exercise" data-editor-exercise data-id="${escapeHTML(x.id||'custom')}" data-name="${escapeHTML(x.name)}" data-item-kind="exercise"><div class="editor-exercise-head">${thumb(known)}<div class="exercise-title"><strong>${escapeHTML(x.name)}</strong><small>${escapeHTML(known?.group||'Movimiento personalizado')}</small></div><button type="button" class="editor-icon-button" data-editor-action="remove-exercise" data-exercise="${i}" title="Eliminar ejercicio" aria-label="Eliminar ${escapeHTML(x.name)}">×</button></div><div class="editor-values">
 ${num(x.sets??3,1,50,'Series','sets')}${num(x.reps??8,0,1000,'Reps','reps')}${num(x.rir??2,0,10,'RIR','rir')}
 ${num(x.weight??0,0,1000,'Kg','weight',.5)}${num(x.duration??0,0,3600,'Seg.','duration')}
 </div><label class="editor-notes">Indicaciones<input data-editor-field="notes" value="${escapeHTML(x.notes||'')}" maxlength="400" placeholder="Tempo, alternativa…"></label></article>`;
}

function libraryPanel(blockIndex){
 return `<div class="editor-block-panel" data-block-panel="library">
  <div class="editor-picker-head"><div><strong>Biblioteca de ejercicios</strong><small>Se añaden a este bloque</small></div>
   <button type="button" class="editor-icon-button" data-editor-action="close-panel" aria-label="Cerrar">×</button></div>
  <input data-editor-search type="search" placeholder="Buscar sentadilla, deadlift, burpee…" aria-label="Buscar ejercicios">
  <div class="editor-picker-results">${MOVEMENTS.map(m=>`<button type="button" class="editor-movement" data-editor-action="pick-exercise" data-id="${m.id}" data-search="${escapeHTML((m.name+' '+m.group+' '+m.id).toLowerCase())}">${thumb(m)}<span><strong>${escapeHTML(m.name)}</strong><small>${escapeHTML(m.group)}</small></span><span aria-hidden="true">＋</span></button>`).join('')}</div>
  <label class="editor-custom">Ejercicio personalizado<input data-editor-custom maxlength="120" placeholder="Nombre del movimiento"></label>
  <button type="button" class="editor-add" data-editor-action="add-custom">Añadir personalizado</button>
 </div>`;
}
function templatesPanel(blockIndex){
 const rows=libraryTemplates.length?libraryTemplates.map(t=>{
  const n=(visualPrescription(t.prescription).blocks||[]).length;
  return `<article class="editor-template-row">
   <div><strong>${escapeHTML(t.name)}</strong><small>${escapeHTML(t.description||'Plantilla')} · ${n} bloque${n===1?'':'s'}</small></div>
   <div class="editor-template-actions">
    <button type="button" class="connected-secondary" data-editor-action="insert-template-into-block" data-id="${escapeHTML(t.id)}">En este bloque</button>
    <button type="button" class="connected-secondary" data-editor-action="insert-template-blocks" data-id="${escapeHTML(t.id)}">Como bloques</button>
   </div>
  </article>`;
 }).join(''):'<p class="connected-hint">Aún no hay plantillas en Mis entrenos.</p>';
 return `<div class="editor-block-panel" data-block-panel="templates">
  <div class="editor-picker-head"><div><strong>Mis entrenos</strong><small>Insertar plantilla en este punto</small></div>
   <button type="button" class="editor-icon-button" data-editor-action="close-panel" aria-label="Cerrar">×</button></div>
  <div class="editor-template-list">${rows}</div>
 </div>`;
}
function timerPanel(blockIndex){
 return `<div class="editor-block-panel" data-block-panel="timer">
  <div class="editor-picker-head"><div><strong>Temporizador</strong><small>Crea un bloque WOD con reloj (como en la app)</small></div>
   <button type="button" class="editor-icon-button" data-editor-action="close-panel" aria-label="Cerrar">×</button></div>
  <div class="editor-timer-grid">
   <label class="connected-field">Formato<select data-timer-format>
    <option value="amrap">AMRAP</option>
    <option value="emom">EMOM</option>
    <option value="tabata" selected>Tabata</option>
    <option value="fortime">For Time</option>
    <option value="circuit">Circuito</option>
   </select></label>
   <label class="connected-field">Minutos / cap<input type="number" data-timer-minutes min="1" max="120" value="8"></label>
   <label class="connected-field">Rondas<input type="number" data-timer-rounds min="1" max="100" value="8"></label>
  </div>
  <div class="editor-template-actions">
   <button type="button" class="connected-secondary" data-editor-action="apply-timer-in-block">Aplicar a este bloque</button>
   <button type="button" class="connected-primary" data-editor-action="apply-timer-new-block">Nuevo bloque temporizador</button>
  </div>
 </div>`;
}

function blockAddBar(i){
 return `<div class="editor-block-addbar" role="toolbar" aria-label="Añadir al bloque">
  <button type="button" class="editor-add" data-editor-action="open-library" data-index="${i}">+ Ejercicio</button>
  <button type="button" class="editor-add subtle" data-editor-action="add-rest-in-block" data-index="${i}">+ Descanso</button>
  <button type="button" class="editor-add subtle" data-editor-action="open-timer" data-index="${i}">+ Temporizador</button>
  <button type="button" class="editor-add subtle" data-editor-action="open-templates" data-index="${i}">+ Mis entrenos</button>
  <button type="button" class="editor-add subtle" data-editor-action="add-block-after" data-index="${i}" data-kind="wod">+ Bloque WOD</button>
 </div>`;
}

function panelForBlock(i,exercises){
 if(editorUI.pickerBlock===i){
  if(editorUI.panel==='none')return null;
  return editorUI.panel;
 }
 // Bloque vacío sin otro panel activo → biblioteca visible dentro del cuadro.
 if(editorUI.pickerBlock<0&&!(exercises||[]).length)return 'library';
 return null;
}

export function editorMarkup(value=emptyPrescription()){
 const blocks=Array.isArray(value?.blocks)?value.blocks:[];
 const open=editorUI.pickerBlock;
 const panel=editorUI.panel;
 return `<div class="workout-editor" data-picker-block="${open}" data-panel="${escapeHTML(panel||'')}">
 <div class="editor-topline"><div><strong>Constructor de entrenamiento</strong><small>Misma estructura que Repera en iPhone y Android (fuerza + WOD)</small></div>
  <div class="editor-toolbar">
   <button type="button" data-editor-action="add-block" data-kind="strength">+ Fuerza</button>
   <button type="button" data-editor-action="add-block" data-kind="wod">+ WOD</button>
   <button type="button" data-editor-action="add-block" data-kind="warmup">+ Calentamiento</button>
   <button type="button" data-editor-action="add-block" data-kind="accessory">+ Accesorios</button>
  </div>
 </div>
 <div class="editor-blocks">${blocks.length?blocks.map((b,i)=>{
  const active=panelForBlock(i,b.exercises);
  const panelHTML=active==='library'?libraryPanel(i):active==='templates'?templatesPanel(i):active==='timer'?timerPanel(i):'';
  const picking=active!=null;
  return `<section class="editor-block ${picking?'is-picking':''}" data-editor-block data-index="${i}">
 <header class="editor-block-header"><span class="editor-block-count">${i+1}</span>${select(b.kind||'strength',TYPES,'kind')}${select(b.format||'sets',FORMATS,'format')}<button type="button" class="editor-icon-button" data-editor-action="remove-block" title="Eliminar bloque" aria-label="Eliminar bloque">×</button></header>
 <div class="editor-block-settings"><label>Nombre del bloque<input data-editor-field="title" maxlength="120" value="${escapeHTML(b.title||TYPES[b.kind]||'Entrenamiento')}"></label>${num(b.rounds??1,1,100,'Rondas','rounds')}${num(b.timeCap??0,0,720,'Límite (min)','timeCap')}</div>
 <div class="editor-exercises">${(b.exercises||[]).map(movementMarkup).join('')||(active==='library'?'':'<p class="editor-block-empty">Añade ejercicios, descansos o un temporizador.</p>')}</div>
 ${blockAddBar(i)}
 ${panelHTML}
 </section>`;
 }).join(''):'<div class="editor-empty">Crea un bloque para empezar a preparar la sesión.</div>'}</div>
 </div>`;
}

export function readPrescription(form){
 const editor=form.matches?.('.workout-editor')?form:form.querySelector('.workout-editor');
 if(!editor)return emptyPrescription();
 return {version:1,blocks:[...editor.querySelectorAll('[data-editor-block]')].map(block=>{
  const get=(parent,key)=>parent.querySelector(`[data-editor-field="${key}"]`)?.value;
  return {kind:get(block,'kind'),format:get(block,'format'),title:get(block,'title'),rounds:integer(get(block,'rounds'),1),timeCap:integer(get(block,'timeCap')),exercises:[...block.querySelectorAll('[data-editor-exercise]')].map(el=>{
    const row={id:el.dataset.id||'custom',name:el.dataset.name||el.querySelector('.exercise-title strong')?.textContent||'',sets:integer(get(el,'sets'),3),reps:integer(get(el,'reps'),8),rir:integer(get(el,'rir'),2),weight:Number(get(el,'weight')||0),duration:integer(get(el,'duration')),notes:get(el,'notes')||''};
    if(el.dataset.itemKind==='rest'||isRestMovement(row)){row.id='rest';row.itemKind='rest';row.isRest=true;}
    return row;
  })};
 })};
}

function refreshEditor(editor,current){
 editor.outerHTML=editorMarkup(current);
}

export function handleEditorClick(event){
 const node=event.target.closest('[data-editor-action]');if(!node)return false;
 const editor=node.closest('.workout-editor');if(!editor)return false;
 const action=node.dataset.editorAction;
 const blockEl=node.closest('[data-editor-block]');
 const blockIndex=blockEl?Number(blockEl.dataset.index):-1;

 if(action==='close-panel'){
  const idx=blockIndex>=0?blockIndex:editorUI.pickerBlock;
  editorUI={pickerBlock:idx,panel:'none'};
  refreshEditor(editor,readPrescription(editor));return true;}
 if(action==='open-library'){
  const idx=Number(node.dataset.index);
  const host=node.closest('form')||editor.parentElement;
  editorUI={pickerBlock:idx,panel:'library'};
  refreshEditor(editor,readPrescription(editor));
  queueMicrotask(()=>host?.querySelector?.(`[data-editor-block][data-index="${idx}"] [data-editor-search]`)?.focus());
  return true;}
 if(action==='open-templates'){editorUI={pickerBlock:Number(node.dataset.index),panel:'templates'};refreshEditor(editor,readPrescription(editor));return true;}
 if(action==='open-timer'){editorUI={pickerBlock:Number(node.dataset.index),panel:'timer'};refreshEditor(editor,readPrescription(editor));return true;}

 const current=readPrescription(editor);
 const focusBlock=Number(node.dataset.index??blockIndex);

 if(action==='add-block'){
  const kind=node.dataset.kind||'strength';
  current.blocks.push({kind,format:kind==='wod'?'amrap':'sets',title:TYPES[kind]||'Bloque',rounds:1,timeCap:kind==='wod'?12:0,exercises:[]});
  editorUI={pickerBlock:current.blocks.length-1,panel:'library'};
 }
 else if(action==='add-block-after'){
  const kind=node.dataset.kind||'wod';
  const at=Math.min(current.blocks.length,focusBlock+1);
  current.blocks.splice(at,0,{kind,format:kind==='wod'?'amrap':'sets',title:TYPES[kind]||'WOD',rounds:1,timeCap:kind==='wod'?12:0,exercises:[]});
  editorUI={pickerBlock:at,panel:'library'};
 }
 else if(action==='add-rest-in-block'){
  const idx=focusBlock;if(!current.blocks[idx])return true;
  const rest=restItem(60);
  // Paridad app: REST solo en WOD; en fuerza se inserta bloque WOD «Descanso» a continuación.
  if(current.blocks[idx].kind==='wod')current.blocks[idx].exercises.push(rest);
  else current.blocks.splice(idx+1,0,{kind:'wod',format:'fortime',title:'Descanso',rounds:1,timeCap:0,exercises:[rest]});
  editorUI={pickerBlock:-1,panel:null};
 }
 else if(action==='apply-timer-in-block'||action==='apply-timer-new-block'){
  const panelRoot=node.closest('.editor-block-panel');
  const format=panelRoot?.querySelector('[data-timer-format]')?.value||'tabata';
  const minutes=Math.max(1,Math.min(120,Number(panelRoot?.querySelector('[data-timer-minutes]')?.value||8)));
  const rounds=Math.max(1,Math.min(100,Number(panelRoot?.querySelector('[data-timer-rounds]')?.value||8)));
  const timerBlock={kind:'wod',format,title:FORMATS[format]||'Temporizador',rounds,timeCap:minutes,exercises:[timerWorkItem()]};
  if(action==='apply-timer-in-block'&&current.blocks[focusBlock]){
   Object.assign(current.blocks[focusBlock],{kind:'wod',format,title:timerBlock.title,rounds,timeCap:minutes});
   if(!current.blocks[focusBlock].exercises.length)current.blocks[focusBlock].exercises.push(timerWorkItem());
  }else{
   const at=current.blocks[focusBlock]?focusBlock+1:current.blocks.length;
   current.blocks.splice(at,0,timerBlock);
  }
  editorUI={pickerBlock:-1,panel:null};
 }
 else if(action==='insert-template-blocks'||action==='insert-template-into-block'){
  const tpl=libraryTemplates.find(t=>t.id===node.dataset.id);if(!tpl)return true;
  const extra=visualPrescription(tpl.prescription);
  if(action==='insert-template-into-block'&&current.blocks[focusBlock]){
   const first=extra.blocks[0];
   if(first?.exercises?.length)current.blocks[focusBlock].exercises.push(...first.exercises.slice(0,40-current.blocks[focusBlock].exercises.length));
   if(extra.blocks.length>1)current.blocks.splice(focusBlock+1,0,...extra.blocks.slice(1));
  }else{
   const at=current.blocks[focusBlock]?focusBlock+1:current.blocks.length;
   current.blocks.splice(at,0,...extra.blocks);
  }
  current.blocks=current.blocks.slice(0,24);
  editorUI={pickerBlock:-1,panel:null};
 }
 else if(action==='remove-block'){current.blocks.splice(blockIndex,1);editorUI={pickerBlock:-1,panel:null};}
 else if(action==='remove-exercise'){const exercise=Number(node.dataset.exercise);current.blocks[blockIndex].exercises.splice(exercise,1);}
 else if(action==='pick-exercise'||action==='add-custom'){
  const idx=editorUI.pickerBlock>=0?editorUI.pickerBlock:blockIndex;
  const match=MOVEMENTS.find(m=>m.id===node.dataset.id);
  const custom=editor.querySelector('[data-editor-custom]')?.value?.trim();
  if(action==='add-custom'&&!custom)return true;
  const id=match?.id||'custom',name=match?.name||custom;
  if(!current.blocks[idx])return true;
  current.blocks[idx].exercises.push({id,name,sets:3,reps:8,rir:2,weight:0,duration:0,notes:''});
  // Mantener biblioteca abierta para añadir varios.
  editorUI={pickerBlock:idx,panel:'library'};
 }else{return false;}
 refreshEditor(editor,current);
 return true;
}

export function handleEditorSearch(event){
 if(!event.target.matches('[data-editor-search]'))return false;
 const editor=event.target.closest('.workout-editor');
 const q=event.target.value.trim().toLocaleLowerCase('es').normalize('NFD').replace(/[\u0300-\u036f]/g,'');
 editor.querySelectorAll('.editor-movement').forEach(el=>{
  const value=el.dataset.search.normalize('NFD').replace(/[\u0300-\u036f]/g,'');
  el.hidden=!value.includes(q);
 });
 return true;
}

const WOD_FORMAT_WIRE={
 sets:'strength',amrap:'amrap',emom:'emom',every:'emom',rft:'forTime',fortime:'forTime',
 tabata:'tabata',circuit:'circuit',chipper:'chipper'
};

/** schemaVersion:1 consumido por iOS/Android. Rest solo como movement isRest en WOD. */
export function canonicalPrescription(prescription,catalog=[]){
 const valid=validatePrescription(prescription);
 const entries=new Map(catalog.map(e=>[String(e.name).toLowerCase(),e]));
 const uid=()=>globalThis.crypto?.randomUUID?.()||'00000000-0000-4000-8000-000000000000';
 const out=[];
 for(const b of valid.blocks){
  // Separar descansos colados en fuerza → bloque WOD «Descanso» (paridad PlanView.insertRest).
  let work=b.exercises.filter(e=>!isRestMovement(e));
  let rests=b.exercises.filter(isRestMovement);
  if(b.kind!=='wod'&&rests.length){
   if(work.length){
    out.push(canonicalBlock({...b,exercises:work},entries,uid,false));
   }
   for(const r of rests){
    out.push(canonicalBlock({kind:'wod',format:'fortime',title:'Descanso',rounds:1,timeCap:0,exercises:[r]},entries,uid,true));
   }
   continue;
  }
  if(b.kind==='wod')work=b.exercises;
  if(!work.length&&!rests.length)continue;
  out.push(canonicalBlock({...b,exercises:work.length?work:b.exercises},entries,uid,b.kind==='wod'));
 }
 if(!out.length)throw Error('Añade al menos un bloque con contenido');
 if(out.length>24)throw Error('Demasiados bloques (máx. 24)');
 return {schemaVersion:1,blocks:out};
}

function canonicalBlock(b,entries,uid,forceWod){
 const wod=forceWod||b.kind==='wod';
 const exercises=b.exercises.map(e=>{
  const rest=isRestMovement(e);
  const known=rest?null:entries.get(e.name.toLowerCase());
  const entry={id:uid(),source:known?'catalog':'free',catalogKey:known?.catalogKey||null,name:rest?'Descanso':(known?.name||e.name)};
  if(rest){
   entry.isRest=true;
   entry.restSeconds=Math.max(5,e.duration||60);
   entry.notes=e.notes||`Descanso ${entry.restSeconds}s`;
   if(wod)entry.reps=1;
   else entry.plannedSets=[{id:uid(),targetReps:1,targetWeightKg:null,targetRir:null}];
   return entry;
  }
  if(wod){
   entry.reps=Math.max(1,e.reps||1);
   entry.notes=e.notes;
  }else{
   entry.plannedSets=Array.from({length:Math.min(e.sets,30)},()=>({
    id:uid(),targetReps:Math.max(1,e.reps||1),
    targetWeightKg:e.weight||null,targetRir:e.rir
   }));
  }
  return entry;
 });
 const onlyRest=exercises.length>0&&exercises.every(e=>e.isRest);
 const canonical={id:uid(),title:b.title.length>1?b.title:(wod?(onlyRest?'Descanso':'WOD'):'Fuerza'),
  kind:wod?'wod':'strength',exercises:wod?[]:exercises,
  movements:wod?exercises:[],notes:''};
 if(wod&&!onlyRest){
  canonical.wodFormat=WOD_FORMAT_WIRE[b.format]||'forTime';
  canonical.rounds=b.rounds;
  canonical.timeCapMinutes=b.timeCap||null;
 }else if(wod&&onlyRest){
  canonical.rounds=1;
  canonical.timeCapMinutes=null;
 }
 return canonical;
}

export function visualPrescription(prescription){
 if(prescription?.version===1)return prescription;
 if(prescription?.schemaVersion!==1)return emptyPrescription();
 return {version:1,blocks:(prescription.blocks||[]).map(b=>{
  const wod=b.kind==='wod',entries=(wod?b.movements:b.exercises)||[];
  const formatWire=b.wodFormat||'';
  return {kind:wod?'wod':(b.kind==='warmup'?'warmup':b.kind==='accessory'?'accessory':'strength'),
   format:wod?({amrap:'amrap',emom:'emom',forTime:'rft',tabata:'tabata',circuit:'circuit',chipper:'chipper',strength:'sets'})[formatWire]||'fortime':'sets',
   title:b.title,rounds:b.rounds||1,timeCap:b.timeCapMinutes||0,
   exercises:entries.map(e=>{
    if(e.isRest)return restItem(e.restSeconds||60);
    return {id:e.catalogKey||'custom',name:e.name,
     sets:wod?1:Math.max(1,e.plannedSets?.length||1),
     reps:wod?e.reps||1:e.plannedSets?.[0]?.targetReps||8,
     rir:wod?0:e.plannedSets?.[0]?.targetRir??2,
     weight:wod?0:e.plannedSets?.[0]?.targetWeightKg||0,duration:0,notes:e.notes||''};
   })};
 })};
}
