import {APP_CATALOG} from './exercise-catalog.js';
import {WOD_CATALOG} from '../data/wod-catalog.js';
// Editor de prescripciones Repera Business. Formato serializable compartido con iOS/Android.
// Paridad PlanView: Sin formato, + Ejercicio / Descanso / Movimiento libre, Añadir bloque, Elegir WOD.
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
// Formatos alineados con WODFormat de ReperaDomain (apps). «none» = Sin formato (como PlanView).
const FORMATS={
 none:'Sin formato',
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
const WOD_FORMAT_KEYS=new Set(['amrap','emom','tabata','rft','fortime','circuit','chipper','every']);
function normalizeFormat(f){return f==null||f===''||f==='none'?'none':f;}
function isWodFormat(f){return WOD_FORMAT_KEYS.has(normalizeFormat(f));}
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
/** Resuelve ficha de catálogo por id, catalogKey o nombre (miniaturas tras round-trip canónico). */
export function resolveMovement(x){
 if(!x)return null;
 const id=String(x.id||'').trim();
 const byId=id&&MOVEMENTS.find(m=>m.id===id);
 if(byId)return byId;
 const key=id.replace(/^catalog:/i,'').trim().toLowerCase();
 const name=String(x.name||key||'').trim().toLowerCase();
 if(!name)return null;
 return MOVEMENTS.find(m=>m.name.toLowerCase()===name)
  ||MOVEMENTS.find(m=>m.name.toLowerCase().startsWith(name)||name.startsWith(m.name.toLowerCase()))
  ||null;
}

/** Plantillas Mis entrenos disponibles en el picker del bloque. */
let libraryTemplates=[];
export function setEditorLibraryTemplates(rows=[]){libraryTemplates=Array.isArray(rows)?rows:[];}
let editorUI={pickerBlock:-1,panel:null};
export function emptyPrescription(){return {version:1,blocks:[]};}
/** Bloque inicial vacío con biblioteca lista (Mis entrenos / programar cliente). */
export function starterPrescription(){
 return {version:1,blocks:[{kind:'strength',format:'none',title:'Bloque 1',rounds:1,timeCap:0,exercises:[]}]};
}
/** Meta de sesión (lugar / favorito / duración) — opcional en wire; apps la ignoran hasta consumo. */
export function sessionMetaMarkup(meta={}){
 const loc=escapeHTML(meta.location||'');
 const dur=integer(meta.durationMinutes,45);
 const fav=meta.favorite===true;
 return `<section class="editor-session-meta" data-session-meta-card>
  <div class="editor-session-meta-grid">
   <label class="editor-number"><span>Duración</span><input data-session-meta="durationMinutes" type="number" min="5" max="720" step="5" value="${dur}"><small>min</small></label>
   <label class="editor-session-place"><span>Añadir lugar</span><input data-session-meta="location" maxlength="250" placeholder="Sala, box, pista…" value="${loc}"></label>
   <label class="editor-session-fav"><span>Favorito</span><input data-session-meta="favorite" type="checkbox" ${fav?'checked':''}></label>
  </div>
 </section>`;
}
export function readSessionMeta(form){
 if(!form)return {};
 const get=k=>form.querySelector(`[data-session-meta="${k}"]`)?.value;
 const fav=form.querySelector('[data-session-meta="favorite"]');
 return {
  location:String(get('location')||'').trim().slice(0,250),
  durationMinutes:Math.max(0,Math.min(720,integer(get('durationMinutes'),0))),
  favorite:fav?.checked===true,
 };
}
export function withSessionMeta(prescription,meta){
 if(!prescription)return prescription;
 const m=meta||{};
 const has=m.location||m.favorite||m.durationMinutes;
 if(!has){
  const rest={...prescription};
  delete rest.meta;
  return rest;
 }
 return {...prescription,meta:{
  ...(m.location?{location:m.location}:{}),
  ...(m.favorite?{favorite:true}:{}),
  ...(m.durationMinutes?{durationMinutes:m.durationMinutes}:{}),
 }};
}
export function visualSessionMeta(prescription){
 const m=prescription?.meta||{};
 return {location:m.location||'',durationMinutes:integer(m.durationMinutes,45),favorite:m.favorite===true};
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
  const format=normalizeFormat(b.format);
  if(!TYPES[b.kind]||!FORMATS[format]||!Array.isArray(b.exercises)||b.exercises.length>40)throw Error('Bloque de entrenamiento no válido');
  const exercises=b.exercises.map(x=>{
   const label=String(x.name||'').trim().slice(0,120);
   if(!label)throw Error('Cada ejercicio debe tener un nombre');
   const sets=integer(x.sets,3),reps=integer(x.reps,8),rir=integer(x.rir,2),weight=Number(x.weight||0),duration=integer(x.duration,0);
   if(sets<1||sets>50||reps<0||reps>1000||rir<0||rir>10||!Number.isFinite(weight)||weight<0||weight>1000||duration<0||duration>3600)throw Error('Revisa series, repeticiones, RIR, peso o duración');
   const row={id:String(x.id||'custom').slice(0,80),name:label,sets,reps,rir,weight,duration,notes:String(x.notes||'').slice(0,400)};
   if(isRestMovement(x)){row.id='rest';row.itemKind='rest';row.isRest=true;}
   if(x.itemKind==='free'||x.source==='free'){row.itemKind='free';row.source='free';}
   return row;
  });
  if(!exercises.length)throw Error('Añade al menos un ejercicio o descanso a cada bloque');
  const kind=isWodFormat(format)&&b.kind!=='warmup'&&b.kind!=='accessory'?'wod':b.kind;
  return {kind,format,title:String(b.title||TYPES[kind]||'Bloque').slice(0,120),rounds:Math.max(1,Math.min(100,integer(b.rounds,1))),timeCap:Math.max(0,Math.min(720,integer(b.timeCap,0))),exercises};
 });
 if(!blocks.length)throw Error('Añade un bloque de fuerza, calentamiento o WOD');
 return {version:1,blocks};
}
function num(value, min, max, label, key, step=1){return `<label class="editor-number"><span>${label}</span><input data-editor-field="${key}" type="number" value="${escapeHTML(value)}" min="${min}" max="${max}" step="${step}"></label>`;}
function select(value,choices,key){return `<select data-editor-field="${key}" aria-label="${key}">${Object.entries(choices).map(([v,t])=>`<option value="${v}" ${v===value?'selected':''}>${t}</option>`).join('')}</select>`;}

function removeBtn(i,label){
 return `<button type="button" class="editor-icon-button is-danger" data-editor-action="remove-exercise" data-exercise="${i}" title="${escapeHTML(label)}" aria-label="${escapeHTML(label)}">
  <span aria-hidden="true">⌫</span></button>`;
}
function movementMarkup(x,i){
 const known=resolveMovement(x);
 if(isRestMovement(x)){
  return `<article class="editor-exercise is-rest" data-editor-exercise data-id="rest" data-name="Descanso" data-item-kind="rest"><div class="editor-exercise-head"><span class="exercise-thumb exercise-thumb-empty" aria-hidden="true">⏱</span><div class="exercise-title"><strong>Descanso</strong><small>Pausa (como en la app)</small></div>${removeBtn(i,'Eliminar descanso')}</div><div class="editor-values">
 ${num(x.duration??60,5,3600,'Segundos','duration')}
 </div><label class="editor-notes">Notas<input data-editor-field="notes" value="${escapeHTML(x.notes||'')}" maxlength="400" placeholder="Opcional"></label>
 <input type="hidden" data-editor-field="sets" value="1"><input type="hidden" data-editor-field="reps" value="0"><input type="hidden" data-editor-field="rir" value="0"><input type="hidden" data-editor-field="weight" value="0"></article>`;
 }
 const free=x.itemKind==='free'||x.source==='free';
 const kind=free?'free':'exercise';
 const subtitle=free?'Movimiento libre':(known?.group||'Movimiento personalizado');
 const art=free?`<span class="exercise-thumb exercise-thumb-empty" aria-hidden="true">＋</span>`:thumb(known||{art:null});
 return `<article class="editor-exercise ${free?'is-free':''}" data-editor-exercise data-id="${escapeHTML(known?.id||x.id||'custom')}" data-name="${escapeHTML(x.name)}" data-item-kind="${kind}"><div class="editor-exercise-head">${art}<div class="exercise-title"><strong>${escapeHTML(x.name)}</strong><small>${escapeHTML(subtitle)}</small></div>${removeBtn(i,`Eliminar ${x.name||'ejercicio'}`)}</div><div class="editor-values">
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
function freeMovementPanel(blockIndex){
 return `<div class="editor-block-panel" data-block-panel="free">
  <div class="editor-picker-head"><div><strong>Movimiento libre</strong><small>Sin ficha de catálogo (como en la app)</small></div>
   <button type="button" class="editor-icon-button" data-editor-action="close-panel" aria-label="Cerrar">×</button></div>
  <label class="connected-field">Nombre<input data-free-name maxlength="120" placeholder="Ej. Farmer carry maleta" required></label>
  <div class="editor-timer-grid">
   <label class="connected-field">Reps / cantidad<input type="number" data-free-reps min="1" max="1000" value="10"></label>
   <label class="connected-field">Series<input type="number" data-free-sets min="1" max="50" value="3"></label>
  </div>
  <button type="button" class="editor-add" data-editor-action="add-free-movement" data-index="${blockIndex}">Añadir movimiento libre</button>
 </div>`;
}
function wodCatalogPanel(blockIndex){
 const rows=WOD_CATALOG.map(w=>{
  const search=`${w.name} ${w.format} ${w.notes||''} ${(w.movements||[]).map(m=>m.name).join(' ')}`.toLowerCase();
  return `<button type="button" class="editor-movement" data-editor-action="insert-wod-template" data-id="${escapeHTML(w.id)}" data-index="${blockIndex}" data-search="${escapeHTML(search)}">
  <span class="exercise-thumb exercise-thumb-empty" aria-hidden="true">☰</span>
  <span><strong>${escapeHTML(w.name)}</strong><small>${escapeHTML(FORMATS[w.format]||w.format)}${w.timeCap?` · ${w.timeCap}'`:''}${w.notes?` · ${escapeHTML(w.notes)}`:''}</small></span>
  <span aria-hidden="true">＋</span>
 </button>`;
 }).join('');
 return `<div class="editor-block-panel" data-block-panel="wod-catalog">
  <div class="editor-picker-head"><div><strong>Elegir WOD</strong><small>Benchmarks conocidos (Girls, Heroes…)</small></div>
   <button type="button" class="editor-icon-button" data-editor-action="close-panel" aria-label="Cerrar">×</button></div>
  <input data-editor-search type="search" placeholder="Buscar Fran, Cindy, Murph…" aria-label="Buscar WOD">
  <div class="editor-picker-results">${rows}</div>
 </div>`;
}

function blockAddBar(i){
 return `<div class="editor-block-addbar" role="toolbar" aria-label="Añadir al bloque">
  <button type="button" class="editor-add" data-editor-action="open-library" data-index="${i}">+ Ejercicio</button>
  <button type="button" class="editor-add subtle" data-editor-action="add-rest-in-block" data-index="${i}">Descanso</button>
  <button type="button" class="editor-add subtle" data-editor-action="open-free" data-index="${i}">+ Movimiento libre</button>
  <button type="button" class="editor-add subtle" data-editor-action="open-timer" data-index="${i}">Temporizador</button>
  <button type="button" class="editor-add subtle" data-editor-action="open-templates" data-index="${i}">Mis entrenos</button>
 </div>`;
}
function editorFooterActions(){
 return `<div class="editor-footer-actions" role="toolbar" aria-label="Añadir al entreno">
  <button type="button" class="editor-footer-btn" data-editor-action="add-block" data-kind="strength">
   <span aria-hidden="true">▦</span> Añadir bloque</button>
  <button type="button" class="editor-footer-btn" data-editor-action="open-global-wod">
   <span aria-hidden="true">☰</span> Elegir WOD</button>
  <button type="button" class="editor-footer-btn" data-editor-action="open-global-templates">
   <span aria-hidden="true">★</span> Mis entrenos</button>
  <button type="button" class="editor-footer-btn" data-editor-action="open-accessories">
   <span aria-hidden="true">＋</span> Accesorios</button>
  <button type="button" class="editor-footer-btn is-muted" data-editor-action="scan-board" title="OCR de pizarra: fase posterior en Business">
   <span aria-hidden="true">▢</span> Escanear pizarra</button>
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

export function editorMarkup(value=emptyPrescription(),{meta=null,showMeta=false}={}){
 const blocks=Array.isArray(value?.blocks)?value.blocks:[];
 const open=editorUI.pickerBlock;
 const panel=editorUI.panel;
 const metaHTML=showMeta?sessionMetaMarkup(meta||visualSessionMeta(value)): '';
 return `<div class="workout-editor" data-picker-block="${open}" data-panel="${escapeHTML(panel||'')}">
 <div class="editor-topline"><div><strong>Constructor de entrenamiento</strong><small>Misma estructura que Repera en iPhone y Android</small></div></div>
 ${metaHTML}
 <div class="editor-blocks">${blocks.length?blocks.map((b,i)=>{
  const active=panelForBlock(i,b.exercises);
  const panelHTML=active==='library'?libraryPanel(i)
   :active==='templates'?templatesPanel(i)
   :active==='timer'?timerPanel(i)
   :active==='free'?freeMovementPanel(i)
   :active==='wod-catalog'?wodCatalogPanel(i)
   :'';
  const picking=active!=null;
  const fmt=normalizeFormat(b.format);
  const showCaps=isWodFormat(fmt);
  return `<section class="editor-block ${picking?'is-picking':''}" data-editor-block data-index="${i}">
 <header class="editor-block-header">
  <input class="editor-block-title" data-editor-field="title" maxlength="120" value="${escapeHTML(b.title||`Bloque ${i+1}`)}" aria-label="Nombre del bloque">
  <button type="button" class="editor-icon-button is-danger" data-editor-action="remove-block" title="Eliminar bloque" aria-label="Eliminar bloque"><span aria-hidden="true">⌫</span></button>
 </header>
 <div class="editor-block-format-row"><span>Formato</span>${select(fmt,FORMATS,'format')}<input type="hidden" data-editor-field="kind" value="${escapeHTML(b.kind||'strength')}"></div>
 ${showCaps?`<div class="editor-block-settings">${num(b.rounds??1,1,100,'Rondas','rounds')}${num(b.timeCap??0,0,720,'Límite (min)','timeCap')}</div>`
  :`<input type="hidden" data-editor-field="rounds" value="${integer(b.rounds,1)}"><input type="hidden" data-editor-field="timeCap" value="${integer(b.timeCap,0)}">`}
 <div class="editor-exercises">${(b.exercises||[]).map(movementMarkup).join('')||(active==='library'||active==='free'?'':'<p class="editor-block-empty">Añade ejercicios, descanso o movimiento libre.</p>')}</div>
 ${blockAddBar(i)}
 ${panelHTML}
 </section>`;
 }).join(''):'<div class="editor-empty">Crea un bloque para empezar a preparar la sesión.</div>'}</div>
 ${editorFooterActions()}
 ${panel==='wod-catalog'&&open<0?wodCatalogPanel(Math.max(0,blocks.length-1)):''}
 ${panel==='templates'&&open<0?templatesPanel(Math.max(0,blocks.length-1)):''}
 </div>`;
}

export function readPrescription(form){
 const editor=form.matches?.('.workout-editor')?form:form.querySelector('.workout-editor');
 if(!editor)return emptyPrescription();
 return {version:1,blocks:[...editor.querySelectorAll('[data-editor-block]')].map(block=>{
  const get=(parent,key)=>parent.querySelector(`[data-editor-field="${key}"]`)?.value;
  const format=normalizeFormat(get(block,'format'));
  let kind=get(block,'kind')||'strength';
  if(isWodFormat(format))kind='wod';
  else if(format==='none'||format==='sets')kind=kind==='warmup'||kind==='accessory'?kind:'strength';
  return {kind,format,title:get(block,'title'),rounds:integer(get(block,'rounds'),1),timeCap:integer(get(block,'timeCap')),exercises:[...block.querySelectorAll('[data-editor-exercise]')].map(el=>{
    const row={id:el.dataset.id||'custom',name:el.dataset.name||el.querySelector('.exercise-title strong')?.textContent||'',sets:integer(get(el,'sets'),3),reps:integer(get(el,'reps'),8),rir:integer(get(el,'rir'),2),weight:Number(get(el,'weight')||0),duration:integer(get(el,'duration')),notes:get(el,'notes')||''};
    if(el.dataset.itemKind==='rest'||isRestMovement(row)){row.id='rest';row.itemKind='rest';row.isRest=true;}
    if(el.dataset.itemKind==='free'){row.itemKind='free';row.source='free';}
    return row;
  })};
 })};
}

function refreshEditor(editor,current){
 const showMeta=!!editor.querySelector('[data-session-meta-card]');
 const meta=showMeta?readSessionMeta(editor.closest('form')||editor.parentElement||editor):null;
 editor.outerHTML=editorMarkup(current,{meta,showMeta});
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
 if(action==='open-free'){editorUI={pickerBlock:Number(node.dataset.index),panel:'free'};refreshEditor(editor,readPrescription(editor));return true;}
 if(action==='open-wod-catalog'||action==='open-global-wod'){
  const idx=action==='open-global-wod'?-1:Number(node.dataset.index);
  editorUI={pickerBlock:idx>=0?idx:Math.max(0,(readPrescription(editor).blocks.length||1)-1),panel:'wod-catalog'};
  refreshEditor(editor,readPrescription(editor));return true;}
 if(action==='open-global-templates'){
  const cur=readPrescription(editor);
  editorUI={pickerBlock:Math.max(0,cur.blocks.length-1),panel:'templates'};
  refreshEditor(editor,cur);return true;}
 if(action==='open-accessories'){
  const cur=readPrescription(editor);
  const last=cur.blocks[cur.blocks.length-1];
  if(last&&last.kind==='accessory'){
   editorUI={pickerBlock:cur.blocks.length-1,panel:'library'};
  }else{
   cur.blocks.push({kind:'accessory',format:'sets',title:'Accesorios',rounds:1,timeCap:0,exercises:[]});
   editorUI={pickerBlock:cur.blocks.length-1,panel:'library'};
  }
  refreshEditor(editor,cur);
  const host=node.closest('form')||editor.parentElement;
  queueMicrotask(()=>host?.querySelector?.(`[data-editor-block][data-index="${editorUI.pickerBlock}"] [data-editor-search]`)?.focus());
  return true;}
 if(action==='scan-board'){
  const host=node.closest('form')||editor.parentElement;
  let note=host?.querySelector?.('[data-scan-board-note]');
  if(!note&&host){
   note=document.createElement('p');
   note.className='connected-hint';
   note.dataset.scanBoardNote='1';
   note.textContent='Escanear pizarra llegará a Business en una fase posterior (ahora está en la app).';
   editor.after(note);
  }
  return true;}

 const current=readPrescription(editor);
 const focusBlock=Number(node.dataset.index??blockIndex);

 if(action==='add-block'){
  const kind=node.dataset.kind||'strength';
  const n=current.blocks.length+1;
  current.blocks.push({
   kind,
   format:kind==='wod'?'amrap':kind==='accessory'?'sets':'none',
   title:kind==='accessory'?'Accesorios':kind==='warmup'?'Calentamiento':`Bloque ${n}`,
   rounds:1,timeCap:kind==='wod'?12:0,exercises:[]
  });
  editorUI={pickerBlock:current.blocks.length-1,panel:'library'};
 }
 else if(action==='add-block-after'){
  const kind=node.dataset.kind||'wod';
  const at=Math.min(current.blocks.length,focusBlock+1);
  current.blocks.splice(at,0,{kind,format:kind==='wod'?'amrap':'none',title:kind==='wod'?'WOD':`Bloque ${at+1}`,rounds:1,timeCap:kind==='wod'?12:0,exercises:[]});
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
 else if(action==='insert-wod-template'){
  const wod=WOD_CATALOG.find(w=>w.id===node.dataset.id);if(!wod)return true;
  const block={
   kind:'wod',format:wod.format||'fortime',title:wod.name,
   rounds:wod.rounds||1,timeCap:wod.timeCap||0,
   exercises:(wod.movements||[]).map(m=>({
    id:'custom',name:m.name,sets:1,reps:m.reps||1,rir:0,
    weight:m.weightMaleKg||0,duration:0,
    notes:m.meters?`${m.meters} m`:(wod.notes||''),
    itemKind:'free',source:'free'
   }))
  };
  if(!block.exercises.length)block.exercises.push(timerWorkItem());
  const at=current.blocks[focusBlock]?focusBlock+1:current.blocks.length;
  current.blocks.splice(at,0,block);
  current.blocks=current.blocks.slice(0,24);
  editorUI={pickerBlock:-1,panel:null};
 }
 else if(action==='add-free-movement'){
  const idx=focusBlock;if(!current.blocks[idx])return true;
  const panelRoot=node.closest('.editor-block-panel');
  const name=String(panelRoot?.querySelector('[data-free-name]')?.value||'').trim().slice(0,120);
  if(!name)return true;
  const reps=Math.max(1,Math.min(1000,Number(panelRoot?.querySelector('[data-free-reps]')?.value||10)));
  const sets=Math.max(1,Math.min(50,Number(panelRoot?.querySelector('[data-free-sets]')?.value||3)));
  current.blocks[idx].exercises.push({id:'custom',name,sets,reps,rir:0,weight:0,duration:0,notes:'',itemKind:'free',source:'free'});
  editorUI={pickerBlock:idx,panel:'free'};
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
 none:null,sets:'strength',amrap:'amrap',emom:'emom',every:'emom',rft:'forTime',fortime:'forTime',
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
  const asWod=b.kind==='wod'||isWodFormat(b.format);
  if(!asWod&&rests.length){
   if(work.length){
    out.push(canonicalBlock({...b,exercises:work},entries,uid,false));
   }
   for(const r of rests){
    out.push(canonicalBlock({kind:'wod',format:'fortime',title:'Descanso',rounds:1,timeCap:0,exercises:[r]},entries,uid,true));
   }
   continue;
  }
  if(asWod)work=b.exercises;
  if(!work.length&&!rests.length)continue;
  out.push(canonicalBlock({...b,exercises:work.length?work:b.exercises},entries,uid,asWod));
 }
 if(!out.length)throw Error('Añade al menos un bloque con contenido');
 if(out.length>24)throw Error('Demasiados bloques (máx. 24)');
 const wire={schemaVersion:1,blocks:out};
 if(prescription?.meta&&typeof prescription.meta==='object')wire.meta=prescription.meta;
 return wire;
}

function canonicalBlock(b,entries,uid,forceWod){
 const wod=forceWod||b.kind==='wod'||isWodFormat(b.format);
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
 if(wod){
  const wired=WOD_FORMAT_WIRE[normalizeFormat(b.format)];
  // validate_professional_prescription exige wodFormat en todo bloque WOD (también Descanso).
  canonical.wodFormat=onlyRest?'forTime':(wired||'forTime');
  canonical.rounds=onlyRest?1:b.rounds;
  canonical.timeCapMinutes=onlyRest?null:(b.timeCap||null);
 }
 // catalogKey null rompe algunos clientes JSON; solo enviar clave cuando hay catálogo.
 for(const list of [canonical.exercises,canonical.movements]){
  for(const e of list){
   if(e.catalogKey==null)delete e.catalogKey;
  }
 }
 return canonical;
}

export function visualPrescription(prescription){
 if(prescription?.version===1){
  const copy={...prescription,blocks:(prescription.blocks||[]).map(b=>({...b,format:normalizeFormat(b.format)}))};
  return copy;
 }
 if(prescription?.schemaVersion!==1)return emptyPrescription();
 const out={version:1,blocks:(prescription.blocks||[]).map(b=>{
  const wod=b.kind==='wod',entries=(wod?b.movements:b.exercises)||[];
  const formatWire=b.wodFormat||'';
  return {kind:wod?'wod':(b.kind==='warmup'?'warmup':b.kind==='accessory'?'accessory':'strength'),
   format:wod?({amrap:'amrap',emom:'emom',forTime:'rft',tabata:'tabata',circuit:'circuit',chipper:'chipper',strength:'sets'})[formatWire]||'fortime'
    :(formatWire?'sets':'none'),
   title:b.title,rounds:b.rounds||1,timeCap:b.timeCapMinutes||0,
   exercises:entries.map(e=>{
    if(e.isRest)return restItem(e.restSeconds||60);
    const free=e.source==='free'||!e.catalogKey;
    return {id:e.catalogKey||'custom',name:e.name,
     sets:wod?1:Math.max(1,e.plannedSets?.length||1),
     reps:wod?e.reps||1:e.plannedSets?.[0]?.targetReps||8,
     rir:wod?0:e.plannedSets?.[0]?.targetRir??2,
     weight:wod?0:e.plannedSets?.[0]?.targetWeightKg||0,duration:0,notes:e.notes||'',
     ...(free?{itemKind:'free',source:'free'}:{})};
   })};
 })};
 if(prescription.meta)out.meta=prescription.meta;
 return out;
}
