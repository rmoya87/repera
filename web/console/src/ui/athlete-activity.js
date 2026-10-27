import {nativeExerciseArt} from './exercise-art-map.js';
// Athlete detail is intentionally presentation-only: show user-facing training
// concepts, never the raw internal IDs, favorite flags or schema field names.
const e=value=>String(value??'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
const asArray=value=>Array.isArray(value)?value:[];
const localDay=(date)=>{if(!date)return '';const d=new Date(date);if(Number.isNaN(d.valueOf()))return '';return new Intl.DateTimeFormat('sv-SE',{year:'numeric',month:'2-digit',day:'2-digit',timeZone:'Europe/Madrid'}).format(d);};
const fmtDate=v=>v?new Date(v).toLocaleDateString('es-ES',{day:'numeric',month:'long',year:'numeric'}):'—';
const fmtClock=v=>v?new Date(v).toLocaleTimeString('es-ES',{hour:'2-digit',minute:'2-digit',timeZone:'Europe/Madrid'}):'';
const amount=(n,unit)=>n==null||n===''?'—':(Number.isFinite(Number(n))?new Intl.NumberFormat('es-ES',{maximumFractionDigits:2}).format(Number(n)):String(n))+(unit?' '+unit:'');
const duration=secs=>{const s=Number(secs);if(!Number.isFinite(s)||s<0)return '—';return Math.floor(s/60)+':'+String(Math.round(s%60)).padStart(2,'0');};
const ascii=t=>String(t||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim();
const exactArtNames = new Map(Object.entries(nativeExerciseArt).map(([name,file])=>[ascii(name),file]));
// Exact match to an artwork verified in the native iOS catalog. Never display a
// different exercise based on a substring or vague muscle-group similarity.
function exerciseArt(name){
 const key=ascii(name);
 const art=exactArtNames.get(key);
 return art?'../assets/exercises/'+art+'.jpg':null;
}
const setLine=(set,i,planned=false)=>{
 const reps=planned?set.targetReps??set.reps:set.reps??set.targetReps;
 const kg=planned?set.targetWeightKg??set.weightKg:set.weightKg??set.targetWeightKg;
 const rir=planned?set.targetRir??set.rir:set.rir??set.targetRir;
 const seconds=set.durationSeconds;
 return `<tr><td><span class="pa-series-number">${i+1}</span></td>
 <td>${e(amount(reps))}</td><td>${e(amount(kg,'kg'))}</td>
 <td>${e(amount(rir))}</td><td>${seconds!=null?e(duration(seconds)):'—'}</td></tr>`;
};
function setsMarkup(ex){
 const logged=asArray(ex.loggedSets),planned=asArray(ex.plannedSets);
 const sets=logged.length?logged:planned;
 if(!sets.length){
  const reps=ex.completedReps;
  return reps!=null?`<div class="pa-exercise-prescribed">Repeticiones completadas: <strong>${e(amount(reps))}</strong></div>`:
   '<p class="pa-muted">Sin series registradas.</p>';
 }
 return `<div class="pa-sets-caption">${logged.length?'Series realizadas':'Series programadas'}</div>
 <div class="pa-table-scroll"><table class="pa-sets-table"><thead><tr>
 <th>Serie</th><th>Repeticiones</th><th>Peso</th><th>RIR</th><th>Tiempo</th></tr></thead><tbody>
 ${sets.map((row,i)=>setLine(row,i,!logged.length)).join('')}</tbody></table></div>`;
}
function blockTitle(ex,index){
 const h=ex.blockHeader;
 if(typeof h==='string'&&h.trim())return h;
 if(h&&typeof h==='object')return h.title||h.name||h.label||'';
 if(ex.blockKind==='wod')return 'WOD';
 if(ex.blockKind==='strength')return 'Fuerza';
 return 'Bloque '+index;
}
const blockLabel=kind=>kind==='wod'?'WOD':kind==='strength'?'Fuerza':'Entrenamiento';
function workoutBlocks(workout){
 const groups=new Map();
 asArray(workout.exercises).forEach((ex,index)=>{
  if(!ex||typeof ex!=='object')return;
  // blockId is used only to group exercises, never displayed in the UI.
  const id=String(ex.blockId??'single-'+index);
  if(!groups.has(id))groups.set(id,{kind:ex.blockKind,title:blockTitle(ex,groups.size+1),exercises:[],rounds:ex.blockRounds,timeCap:ex.blockTimeCapMinutes,format:ex.wodFormat});
  groups.get(id).exercises.push(ex);
 });
 const list=[...groups.values()];
 return list.length?list.map((block,index)=>`<section class="pa-workout-block">
  <div class="pa-workout-block-head"><span class="pa-block-index">${index+1}</span>
  <div><span class="pa-eyebrow">${e(blockLabel(block.kind))}</span><h4>${e(block.title||'Bloque '+(index+1))}</h4>
   <small>${[block.format,block.rounds?'Rondas: '+block.rounds:null,block.timeCap?'Límite: '+block.timeCap+' min':null].filter(Boolean).map(e).join(' · ')}</small></div></div>
  <div class="pa-workout-exercises">${block.exercises.map(ex=>{
   const name=ex.exercise?.name||ex.exerciseName||'Ejercicio';
   const image=exerciseArt(name);
   return `<article class="pa-exercise-card"><div class="pa-exercise-head">
    ${image?`<img src="${image}" class="pa-exercise-photo" alt="" loading="lazy">`:
     '<div class="pa-exercise-photo pa-exercise-placeholder" aria-hidden="true">✦</div>'}
    <div class="pa-exercise-name"><strong>${e(name)}</strong>
    <small>${ex.isCompleted===true?'Completado':ex.isCompleted===false?'Sin marcar como completado':''}</small></div></div>
    ${setsMarkup(ex)}</article>`;
  }).join('')}</div></section>`).join(''):
  '<p class="pa-muted">Este entrenamiento no contiene ejercicios detallados en la sincronización.</p>';
}
function wodResults(workout){
 const results=asArray(workout.wod_results);
 if(!results.length)return '';
 return `<section class="pa-wod-results"><h4>Resultados del WOD</h4><div class="pa-wod-stats">
 ${results.map(x=>`<div><small>${e(x.format||'WOD')}</small>
 ${x.roundsCompleted!=null?`<strong>${e(amount(x.roundsCompleted))} rondas</strong>`:''}
 ${x.totalReps!=null?`<span>${e(amount(x.totalReps))} repeticiones</span>`:''}
 ${x.elapsedSeconds!=null?`<span>${e(duration(x.elapsedSeconds))} min</span>`:''}</div>`).join('')}</div></section>`;
}
function workoutCard(w,i){
 const time=w.started_at?fmtClock(w.started_at):'';
 const finish=w.finished_at?' · Finalizado':'';
 return `<details class="pa-workout-record" ${i===0?'open':''}><summary>
 <span class="pa-record-icon" aria-hidden="true">✓</span><span>
 <strong>${e(w.title||'Entrenamiento')}</strong><small>${e(time+finish)}</small></span>
 <span class="pa-record-chevron" aria-hidden="true">⌄</span></summary>
 <div class="pa-record-body">${workoutBlocks(w)}${wodResults(w)}</div></details>`;
}
export function renderAthleteActivity({month,days=[],selectedDay='',workouts=[],loading=false,canPlan=false,athleteId=''}={}){
 const safeMonth=/^\d{4}-\d{2}$/.test(month||'')?month:new Date().toLocaleDateString('sv-SE').slice(0,7);
 const [year,m]=safeMonth.split('-').map(Number);
 const first=(new Date(Date.UTC(year,m-1,1)).getUTCDay()+6)%7;
 const length=new Date(Date.UTC(year,m,0)).getUTCDate();
 const countByDay=new Map(asArray(days).map(d=>[String(d.day),Number(d.count)||0]));
 const title=new Intl.DateTimeFormat('es-ES',{month:'long',year:'numeric',timeZone:'UTC'}).format(new Date(Date.UTC(year,m-1,1)));
 const cells=Array.from({length:first+length},(_,i)=>{
  const day=i-first+1;if(day<=0)return '<span class="pa-activity-empty" aria-hidden="true"></span>';
  const value=safeMonth+'-'+String(day).padStart(2,'0');
  const count=countByDay.get(value)||0;
  return `<button type="button" class="pa-activity-day ${count?'has-activity':''} ${value===selectedDay?'selected':''}"
   data-admin-action="athlete-day" data-day="${e(value)}" aria-label="${e(day+' de '+title+(count?' · '+count+' entrenamientos':' · sin entrenamientos'))}"
   aria-pressed="${value===selectedDay?'true':'false'}">
   <span>${day}</span><i class="pa-activity-dot" aria-hidden="true"></i></button>`;
 }).join('');
 return `<section class="pa-panel pa-activity-panel"><div class="pa-activity-heading">
  <div><span class="pa-eyebrow">Actividad</span><h2>Calendario de entrenamientos</h2>
  <p class="pa-muted">Selecciona un día para ver sus ejercicios y resultados tal como se realizaron.</p></div>
  <div class="pa-calendar-actions">
   <button type="button" data-admin-action="athlete-month" data-step="-1" aria-label="Mes anterior">‹</button>
   <strong>${e(title)}</strong>
   <button type="button" data-admin-action="athlete-month" data-step="1" aria-label="Mes siguiente">›</button></div></div>
  <div class="pa-activity-weekdays">${['L','M','X','J','V','S','D'].map(d=>`<span>${d}</span>`).join('')}</div>
  <div class="pa-activity-calendar">${cells}</div>
  <div class="pa-activity-legend"><span class="pa-activity-dot has"></span>Día con entrenamiento <span class="pa-activity-dot"></span>Sin actividad</div>
  </section>
  <section class="pa-panel pa-activity-workouts"><div class="pa-activity-right-heading">
  <h2>${selectedDay?'Entrenamientos del '+e(fmtDate(selectedDay+'T12:00:00Z')):'Selecciona un día'}</h2>
  ${canPlan&&selectedDay?`<button type="button" class="pa-button primary"
  data-admin-action="schedule-athlete" data-id="${e(athleteId)}" data-day="${e(selectedDay)}">+ Añadir entrenamiento</button>`:''}</div>
  ${loading?'<p class="pa-muted">Cargando entrenamientos...</p>':
    !selectedDay?'<p class="pa-muted">Los días señalados en verde tienen actividad registrada.</p>':
    workouts.length?workouts.map(workoutCard).join(''):
   '<div class="pa-activity-none">No hay entrenamientos registrados este día.</div>'}
  </section>`;
}

/** Read-only training cards for coaches after Supabase verifies sharing consent. */
export function renderSharedAthleteSessions(rows=[]){
 const safe=Array.isArray(rows)?rows:[];
 if(!safe.length)return '<p class="pa-muted">El atleta no ha compartido entrenamientos con este centro o aún no tiene actividad sincronizada.</p>';
 return `<div class="pa-shared-workouts">${safe.slice(0,30).map((row,index)=>{
   const data=row?.result&&typeof row.result==='object'?row.result:{};
   const exercises=Array.isArray(data.exercises)?data.exercises:[];
   const wod=Array.isArray(data.wodResults)?data.wodResults:[];
   return workoutCard({title:row.title,started_at:row.started_at,
    finished_at:row.finished_at,exercises,wod_results:wod},index);
 }).join('')}</div>`;
}
