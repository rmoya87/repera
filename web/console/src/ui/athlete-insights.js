import {nativeBodyPaths} from './body-paths-data.js';
// Coaching insights derived only from actually logged workouts (no medical data).
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>new Intl.NumberFormat('es-ES',{maximumFractionDigits:1}).format(n);
const norm=s=>String(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
const matchMuscle=(group,name)=>{
 const text=norm([group,name].join(' '));
 if(/sentadilla|squat|cuadricep|quad|prensa/.test(text))return 'Piernas';
 if(/deadlift|peso muerto|femoral|isquio|hamstring|glute|zancada|lunge/.test(text))return 'Cadena posterior';
 if(/pecho|pectoral|chest|banca|push.up|press/.test(text))return 'Pecho y empuje';
 if(/remo|row|espalda|dorsal|pull|dominada|back/.test(text))return 'Espalda y tirón';
 if(/hombro|shoulder|deltoid|elevacion lateral/.test(text))return 'Hombros';
 if(/biceps|triceps|curl|brazo/.test(text))return 'Brazos';
 if(/core|abs|abdominal|plancha|plank/.test(text))return 'Core';
 return null;
};
export function deriveCoachingInsights(workouts=[],total=null){
 const records=new Map(),muscles=new Map();
 const sessions=workouts.filter(w=>w?.started_at&&Array.isArray(w.exercises));
 let completed=0,logged=0;
 for(const w of sessions){
  for(const ex of w.exercises){
   const name=String(ex.exercise?.name||ex.exerciseName||'Ejercicio');
   const group=matchMuscle(ex.exercise?.muscleGroup||ex.exercise?.primaryMuscle,name);
   if(group)muscles.set(group,(muscles.get(group)||0)+1);
   for(const set of Array.isArray(ex.loggedSets)?ex.loggedSets:[]){
    const kg=Number(set.weightKg??set.weight),reps=Number(set.reps);
    if(!Number.isFinite(kg)||kg<=0||!Number.isFinite(reps)||reps<=0)continue;
    logged++;
    const prev=records.get(name)||{name,bestKg:0,bestReps:0,e1rm:0};
    if(kg>prev.bestKg){prev.bestKg=kg;prev.bestReps=reps;}
    // Epley is indicative, for non-fatiguing resistance sets of 1–10 reps.
    if(reps<=10)prev.e1rm=Math.max(prev.e1rm,kg*(1+reps/30));
    records.set(name,prev);
  }
  if(ex.isCompleted===true)completed++;
  }
 }
 const best=[...records.values()].sort((a,b)=>b.e1rm-a.e1rm||b.bestKg-a.bestKg).slice(0,8);
 const uniqueDays=new Set(sessions.map(w=>String(w.started_at).slice(0,10))).size;
 const sampleSize=sessions.length,coverage=muscles.size;
 // A *logging consistency* indicator, not a health/fitness or professional qualification.
 const rating=Math.max(0,Math.min(100,Math.round(
  Math.min(sampleSize/24,1)*40+Math.min(uniqueDays/18,1)*25+
  Math.min(coverage/7,1)*20+Math.min(logged/100,1)*15)));
 const label=rating<35?'Amateur':rating<70?'Medio':'Avanzado';
 const recommendations=[];
 if(sampleSize<5)recommendations.push('Registra más sesiones para obtener referencias de progreso fiables.');
 if(coverage<3)recommendations.push('Revisa el equilibrio de grupos musculares antes de aumentar el volumen.');
 if(logged<10)recommendations.push('Completa las cargas y repeticiones para estimar marcas de fuerza.');
 if(!recommendations.length)recommendations.push('Planifica progresiones graduales y comprueba recuperación y técnica con el deportista.');
 return {best,muscles:[...muscles.entries()].sort((a,b)=>b[1]-a[1]),sampleSize,uniqueDays,logged,rating,label,recommendations,total};
}
// Misma jerarquía de músculos y siluetas (BodyPaths) que la app iOS.
// Replica la escala ABSOLUTA de MuscleMapEngine; nunca normaliza un atleta respecto a otro.
const muscleNames={
 'trapezius':'Trapecio','deltoids':'Hombros','chest':'Pecho','upper-back':'Espalda alta',
 'serratus':'Serrato','biceps':'Bíceps','triceps':'Tríceps','forearm':'Antebrazos',
 'abs':'Abdomen','obliques':'Oblicuos','lower-back':'Lumbar','gluteal':'Glúteos',
 'quadriceps':'Cuádriceps','hamstring':'Isquios','adductors':'Aductores',
 'hip-flexors':'Flexores de cadera','calves':'Gemelos','tibialis':'Tibial'
};
const halfLives={'gluteal':48,'quadriceps':48,'hamstring':48,'adductors':40,
 'lower-back':36,'hip-flexors':36,'calves':36,'chest':30,'upper-back':30,
 'trapezius':28,'deltoids':24,'serratus':24,'biceps':24,'triceps':24,
 'forearm':20,'abs':24,'obliques':24,'tibialis':24};
const alias={pecho:'chest',chest:'chest',pectorals:'chest',espalda:'upper-back',
 back:'upper-back',lats:'upper-back',hombros:'deltoids',shoulders:'deltoids',
 biceps:'biceps',triceps:'triceps',brazo:'biceps',antebrazos:'forearm',
 piernas:'quadriceps',squat:'quadriceps',quads:'quadriceps',
 'cadena posterior':'hamstring',isquios:'hamstring',hamstrings:'hamstring',
 gluteos:'gluteal',glutes:'gluteal',gemelos:'calves',calves:'calves',
 core:'abs',abdominales:'abs',abs:'abs',oblicuos:'obliques'};
const fallbackRegions={Piernas:{quadriceps:.4,hamstring:.35,gluteal:.25},
 'Cadena posterior':{hamstring:.7,gluteal:.3},'Pecho y empuje':{chest:1},
 'Espalda y tirón':{'upper-back':.8,biceps:.2},Hombros:{deltoids:1},
 Brazos:{biceps:.5,triceps:.5},Core:{abs:.7,obliques:.3}};
const canon=v=>{
 const s=norm(v).trim();
 return Object.prototype.hasOwnProperty.call(muscleNames,s)?s:(alias[s]||null);
};
function loadByMuscle(workouts){
 const load={},now=Date.now();
 for(const workout of workouts){
  const time=Date.parse(workout.finished_at||workout.started_at||'');
  const age=(now-time)/3600000;
  if(!Number.isFinite(age)||age<0||age>=720)continue;
  for(const ex of Array.isArray(workout.exercises)?workout.exercises:[]){
   if(norm(ex.exercise?.sportTag)==='movilidad')continue;
   const sets=(Array.isArray(ex.loggedSets)?ex.loggedSets:[]).filter(s=>Number(s.reps)>0&&s.isWarmup!==true);
   // No imputar series planificadas ni resultados sin evidencia de ejecución.
   if(!sets.length)continue;
   const meta=ex.exercise||{}, weights={};
   const put=(key,w)=>{const slug=canon(key);if(slug)weights[slug]=Math.max(weights[slug]||0,w);};
   put(meta.targetMuscle,1);
   for(const region of Array.isArray(meta.primaryRegions)?meta.primaryRegions:[])put(region,1);
   const secondary=[...(Array.isArray(meta.secondaryMuscles)?meta.secondaryMuscles:[]),
     ...(Array.isArray(meta.secondaryRegions)?meta.secondaryRegions:[])];
   secondary.forEach((v,i)=>put(v,i===0?.55:.35));
   put(meta.muscleGroup||meta.primaryMuscle,.2);
   if(!Object.keys(weights).length){
    const group=matchMuscle(meta.muscleGroup||meta.primaryMuscle,ex.exerciseName||meta.name);
    Object.assign(weights,fallbackRegions[group]||{});
   }
   for(const [slug,weight] of Object.entries(weights)){
    const fatigue=Math.min(12,sets.length)*weight*Math.pow(.5,age/(halfLives[slug]||30))/8;
    load[slug]=Math.min(1.5,(load[slug]||0)+fatigue);
   }
  }
 }
 return load;
}
const bodyLevel=score=>score<=0?0:score<.25?1:score<.5?2:score<.85?3:4;
const palette=['#3b3b3d','#178247','#e5bd32','#e9842a','#df4848'];
function silhouette(workouts){
 const load=loadByMuscle(workouts),inert=new Set(['head','hair','neck','hands','feet','knees','ankles']);
 const view=(name,model)=>{
  const box=String(model.vb).trim().split(/[,\\s]+/).map(Number);
  if(box.length!==4||box.some(n=>!Number.isFinite(n)))return '';
  const shapes=Object.entries(model.p||{}).map(([slug,paths])=>{
   const level=inert.has(slug)?0:bodyLevel(load[slug]||0);
   const fill=inert.has(slug)?'#aeb8b2':palette[level];
   const title=muscleNames[slug]||slug;
   return (Array.isArray(paths)?paths:[]).map(p=>`<path d="${esc(p)}" fill="${fill}" stroke="#fff" stroke-width="2" stroke-linejoin="round"><title>${esc(title)} · ${level===0?'Sin estímulo':level===1?'Listo':level===2?'Suave':level===3?'Recuperando':'Fatigado'}</title></path>`).join('');
  }).join('');
  return `<figure><svg class="pa-muscle-map-native" viewBox="${box.join(' ')}" role="img" aria-label="Vista ${esc(name)} del cuerpo con músculos coloreados por estímulo retenido">${shapes}</svg><figcaption>${esc(name)}</figcaption></figure>`;
 };
 const muscles=Object.entries(load).filter(x=>x[1]>0).sort((a,b)=>b[1]-a[1]);
 return `<div class="pa-muscle-views">${view('Delante',nativeBodyPaths.male.front)}${view('Detrás',nativeBodyPaths.male.back)}</div>
 <div class="pa-muscle-legend">${['Sin datos','Listo','Suave','Recuperando','Fatigado'].map((t,i)=>`<span><i style="background:${palette[i]}"></i>${t}</span>`).join('')}</div>
 <div class="pa-muscle-rank">${muscles.slice(0,6).map(([k,v])=>`<span><i style="background:${palette[bodyLevel(v)]}"></i>${esc(muscleNames[k]||k)}</span>`).join('')||'<span>Sin series realizadas con detalle muscular</span>'}</div>`;
}
export function renderAthleteGuidance(workouts=[],total=null){
 const d=deriveCoachingInsights(workouts,total);
 return `<div class="pa-coaching-inline"><div class="pa-coaching-score"><strong>${d.rating}<small>/100</small></strong>
 <div><span>Registro ${esc(d.label)}</span><small>Indicador de consistencia del registro, no nivel físico ni diagnóstico.</small></div></div>
 <div class="pa-insight-stats"><span>${d.uniqueDays} días</span><span>${d.logged} series anotadas</span><span>${d.muscles.length} grupos</span></div>
 <details><summary>Orientación de entrenamiento</summary><ul>${d.recommendations.map(item=>`<li>${esc(item)}</li>`).join('')}</ul><p class="pa-muted">Basado solo en el historial compartido.</p></details></div>`;
}
export function renderAthleteInsights(workouts=[],total=null,{showGuidance=true}={}){
 const d=deriveCoachingInsights(workouts,total);
 return `<div class="pa-athlete-insights">
 <section class="pa-panel"><div class="pa-panel-title"><h2>Máximas y récords</h2>
 <span class="pa-muted">Últimos ${d.sampleSize} entrenamientos cargados</span></div>
 ${d.best.length?`<div class="pa-record-list">${d.best.map(r=>`<article><div><strong>${esc(r.name)}</strong>
 <small>Máximo anotado: ${fmt(r.bestKg)} kg · ${r.bestReps} rep.</small></div>
 <div class="pa-e1rm"><small>e1RM aprox.</small><strong>${r.e1rm?fmt(r.e1rm)+' kg':'—'}</strong></div></article>`).join('')}</div>`:
 '<p class="pa-muted">Todavía no hay series de fuerza con peso y repeticiones suficientes para calcular récords.</p>'}
 <p class="pa-muted">e1RM calculado con Epley para series de hasta 10 repeticiones. No equivale a un test de 1RM.</p>
 </section>
 <section class="pa-panel"><h2>Mapa de grupos trabajados</h2>${silhouette(workouts)}
 <p class="pa-muted">Verde → amarillo → naranja → rojo = más estímulo retenido; recuperación estimada con las mismas bandas que iOS. Solo cuenta series realmente registradas y disponibles; los datos no compartidos no aparecen.</p>
 </section>
 ${showGuidance?`<section class="pa-panel"><h2>Orientación de entrenamiento</h2>${renderAthleteGuidance(workouts,total)}</section>`:''}</div>`;
}
