// Editor de prescripciones Repera Business. Formato serializable compartido con iOS.
const MOVEMENTS = [
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
const TYPES={strength:'Fuerza',wod:'WOD / Metcon',warmup:'Calentamiento',accessory:'Accesorios'};
const FORMATS={sets:'Series',amrap:'AMRAP',emom:'EMOM',rft:'RFT',every:'Every / Intervalos',fortime:'For Time'};
const escapeHTML=value=>String(value??'').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[ch]));
const integer=(v,def=0)=>Number.isFinite(Number(v))?Math.round(Number(v)):def;
const thumb=m=>m?.art?`<img class="exercise-thumb" loading="lazy" src="../../assets/exercises/${m.art}.jpg" alt="" onerror="this.hidden=true">`:'<span class="exercise-thumb exercise-thumb-empty" aria-hidden="true">＋</span>';
const catalog=()=>MOVEMENTS;
export function emptyPrescription(){return {version:1,blocks:[]};}
export function validatePrescription(value){
 if(!value||value.version!==1||!Array.isArray(value.blocks)||value.blocks.length>24)throw Error('Estructura de entrenamiento no válida');
 const blocks=value.blocks.map(b=>{
  if(!TYPES[b.kind]||!FORMATS[b.format]||!Array.isArray(b.exercises)||b.exercises.length>40)throw Error('Bloque de entrenamiento no válido');
  const exercises=b.exercises.map(x=>{
   const label=String(x.name||'').trim().slice(0,120);
   if(!label)throw Error('Cada ejercicio debe tener un nombre');
   const sets=integer(x.sets,3),reps=integer(x.reps,8),rir=integer(x.rir,2),weight=Number(x.weight||0),duration=integer(x.duration,0);
   if(sets<1||sets>50||reps<0||reps>1000||rir<0||rir>10||weight<0||weight>1000||duration<0||duration>3600)throw Error('Revisa series, repeticiones, RIR, peso o duración');
   return {id:String(x.id||'custom').slice(0,80),name:label,sets,reps,rir,weight,duration,notes:String(x.notes||'').slice(0,400)};
  });
  if(!exercises.length)throw Error('Añade al menos un ejercicio a cada bloque');
  return {kind:b.kind,format:b.format,title:String(b.title||TYPES[b.kind]).slice(0,120),rounds:Math.max(1,Math.min(100,integer(b.rounds,1))),timeCap:Math.max(0,Math.min(720,integer(b.timeCap,0))),exercises};
 });
 if(!blocks.length)throw Error('Añade un bloque de fuerza, calentamiento o WOD');
 return {version:1,blocks};
}
function num(value, min, max, label, key, step=1){return `<label class="editor-number"><span>${label}</span><input data-editor-field="${key}" type="number" value="${escapeHTML(value)}" min="${min}" max="${max}" step="${step}"></label>`;}
function select(value,choices,key){return `<select data-editor-field="${key}" aria-label="${key}">${Object.entries(choices).map(([v,t])=>`<option value="${v}" ${v===value?'selected':''}>${t}</option>`).join('')}</select>`;}
function movementMarkup(x,i){
 const known=MOVEMENTS.find(m=>m.id===x.id);
 return `<article class="editor-exercise" data-editor-exercise data-id="${escapeHTML(x.id||'custom')}" data-name="${escapeHTML(x.name)}"><div class="editor-exercise-head">${thumb(known)}<div class="exercise-title"><strong>${escapeHTML(x.name)}</strong><small>${escapeHTML(known?.group||'Movimiento personalizado')}</small></div><button type="button" class="editor-icon-button" data-editor-action="remove-exercise" data-exercise="${i}" title="Eliminar ejercicio" aria-label="Eliminar ${escapeHTML(x.name)}">×</button></div><div class="editor-values">
 ${num(x.sets??3,1,50,'Series','sets')}${num(x.reps??8,0,1000,'Reps','reps')}${num(x.rir??2,0,10,'RIR','rir')}
 ${num(x.weight??0,0,1000,'Kg','weight',.5)}${num(x.duration??0,0,3600,'Seg.','duration')}
 </div><label class="editor-notes">Indicaciones<input data-editor-field="notes" value="${escapeHTML(x.notes||'')}" maxlength="400" placeholder="Tempo, descanso, alternativa…"></label></article>`;
}
export function editorMarkup(value=emptyPrescription()){
 const blocks=Array.isArray(value?.blocks)?value.blocks:[];
 return `<div class="workout-editor">
 <div class="editor-topline"><div><strong>Constructor de entrenamiento</strong><small>Bloques, WOD y ejercicios como en Repera iOS</small></div><div class="editor-toolbar"><button type="button" data-editor-action="add-block" data-kind="strength">+ Fuerza</button><button type="button" data-editor-action="add-block" data-kind="wod">+ WOD</button><button type="button" data-editor-action="add-block" data-kind="warmup">+ Calentamiento</button></div></div>
 <div class="editor-blocks">${blocks.length?blocks.map((b,i)=>`<section class="editor-block" data-editor-block data-index="${i}">
 <header class="editor-block-header"><span class="editor-block-count">${i+1}</span>${select(b.kind||'strength',TYPES,'kind')}${select(b.format||'sets',FORMATS,'format')}<button type="button" class="editor-icon-button" data-editor-action="remove-block" title="Eliminar bloque" aria-label="Eliminar bloque">×</button></header>
 <div class="editor-block-settings"><label>Nombre del bloque<input data-editor-field="title" maxlength="120" value="${escapeHTML(b.title||TYPES[b.kind]||'Entrenamiento')}"></label>${num(b.rounds??1,1,100,'Rondas','rounds')}${num(b.timeCap??0,0,720,'Límite (min)','timeCap')}</div>
 <div class="editor-exercises">${(b.exercises||[]).map(movementMarkup).join('')}</div>
 <button type="button" class="editor-add" data-editor-action="choose-exercise">+ Añadir movimiento</button>
 </section>`).join(''):'<div class="editor-empty">Crea un bloque para empezar a preparar la sesión.</div>'}</div>
 <div class="editor-picker" hidden><div class="editor-picker-head"><div><strong>Biblioteca de movimientos</strong><small>Busca por nombre en español o inglés</small></div><button type="button" class="editor-icon-button" data-editor-action="close-picker" aria-label="Cerrar biblioteca">×</button></div>
 <input data-editor-search type="search" placeholder="Buscar sentadilla, deadlift, burpee…" aria-label="Buscar ejercicios"><div class="editor-picker-results">${MOVEMENTS.map(m=>`<button type="button" class="editor-movement" data-editor-action="pick-exercise" data-id="${m.id}" data-search="${escapeHTML((m.name+' '+m.group+' '+m.id).toLowerCase())}">${thumb(m)}<span><strong>${escapeHTML(m.name)}</strong><small>${escapeHTML(m.group)}</small></span><span aria-hidden="true">＋</span></button>`).join('')}</div>
 <label class="editor-custom">Ejercicio personalizado<input data-editor-custom maxlength="120" placeholder="Nombre del movimiento"></label><button type="button" class="editor-add" data-editor-action="add-custom">Añadir ejercicio personalizado</button></div></div>`;
}
export function readPrescription(form){
 const editor=form.matches?.('.workout-editor')?form:form.querySelector('.workout-editor');
 if(!editor)return emptyPrescription();
 return {version:1,blocks:[...editor.querySelectorAll('[data-editor-block]')].map(block=>{
  const get=(parent,key)=>parent.querySelector(`[data-editor-field="${key}"]`)?.value;
  return {kind:get(block,'kind'),format:get(block,'format'),title:get(block,'title'),rounds:integer(get(block,'rounds'),1),timeCap:integer(get(block,'timeCap')),exercises:[...block.querySelectorAll('[data-editor-exercise]')].map(el=>({
    id:el.dataset.id||'custom',name:el.dataset.name||el.querySelector('.exercise-title strong')?.textContent||'',sets:integer(get(el,'sets'),3),reps:integer(get(el,'reps'),8),rir:integer(get(el,'rir'),2),weight:Number(get(el,'weight')||0),duration:integer(get(el,'duration')),notes:get(el,'notes')||''
  }))};
 })};
}
let pickerIndex=-1;
export function handleEditorClick(event){
 const node=event.target.closest('[data-editor-action]');if(!node)return false;
 const editor=node.closest('.workout-editor');if(!editor)return false;
 const action=node.dataset.editorAction;
 if(action==='close-picker'){editor.querySelector('.editor-picker').hidden=true;return true;}
 if(action==='choose-exercise'){pickerIndex=Number(node.closest('[data-editor-block]').dataset.index);editor.querySelector('.editor-picker').hidden=false;editor.querySelector('[data-editor-search]').focus();return true;}
 const current=readPrescription(editor);
 if(action==='add-block'){let kind=node.dataset.kind||'strength';current.blocks.push({kind,format:kind==='wod'?'amrap':'sets',title:TYPES[kind],rounds:1,timeCap:kind==='wod'?12:0,exercises:[]});}
 else if(action==='remove-block'){current.blocks.splice(Number(node.closest('[data-editor-block]').dataset.index),1);}
 else if(action==='remove-exercise'){const index=Number(node.closest('[data-editor-block]').dataset.index),exercise=Number(node.dataset.exercise);current.blocks[index].exercises.splice(exercise,1);}
 else if(action==='pick-exercise'||action==='add-custom'){
  const match=MOVEMENTS.find(m=>m.id===node.dataset.id);
  const custom=editor.querySelector('[data-editor-custom]')?.value?.trim();
  if(action==='add-custom'&&!custom)return true;
  const id=match?.id||'custom',name=match?.name||custom;
  if(!current.blocks[pickerIndex])return true;
  current.blocks[pickerIndex].exercises.push({id,name,sets:3,reps:8,rir:2,weight:0,duration:0,notes:''});
 }else{return false;}
 editor.outerHTML=editorMarkup(current);
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