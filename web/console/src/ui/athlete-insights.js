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
function silhouette(muscles){
 const activity=new Map(muscles);
 const strength=key=>Math.min(0.78,.1+(activity.get(key)||0)*.085);
 const shape=(label,x,y,rx,ry,group)=>{
  const active=activity.get(group)||0;
  return `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${active?'#42be71':'#e5ebe6'}"
    fill-opacity="${active?strength(group):1}" stroke="#b9cec0" stroke-width="1"><title>${esc(label)}: ${active} ejercicios registrados</title></ellipse>`;
 };
 // Schematic *training stimulus*, not a diagnostic body composition diagram.
 return `<svg class="pa-muscle-map" viewBox="0 0 270 220" role="img"
 aria-label="Mapa orientativo de grupos musculares trabajados en las sesiones registradas">
 <g>${shape('Cabeza',68,22,14,16,'Core')}
 ${shape('Pecho',68,66,30,28,'Pecho y empuje')}
 ${shape('Hombro izquierdo',35,59,12,15,'Hombros')}
 ${shape('Hombro derecho',101,59,12,15,'Hombros')}
 ${shape('Brazos',22,102,9,33,'Brazos')}${shape('Brazos',114,102,9,33,'Brazos')}
 ${shape('Abdomen',68,112,24,22,'Core')}
 ${shape('Piernas',51,167,14,36,'Piernas')}${shape('Piernas',85,167,14,36,'Piernas')}</g>
 <g>${shape('Cabeza',201,22,14,16,'Core')}
 ${shape('Espalda',201,75,32,32,'Espalda y tirón')}
 ${shape('Hombros',165,63,12,14,'Hombros')}${shape('Hombros',237,63,12,14,'Hombros')}
 ${shape('Brazos',154,104,9,33,'Brazos')}${shape('Brazos',248,104,9,33,'Brazos')}
 ${shape('Zona lumbar',201,123,24,18,'Core')}
 ${shape('Posterior',182,168,13,34,'Cadena posterior')}${shape('Posterior',220,168,13,34,'Cadena posterior')}</g>
 <text x="68" y="215" text-anchor="middle" font-size="10" fill="#6d8b75">Delante</text>
 <text x="201" y="215" text-anchor="middle" font-size="10" fill="#6d8b75">Detrás</text></svg>`;
}
export function renderAthleteInsights(workouts=[],total=null){
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
 <section class="pa-panel"><h2>Mapa de grupos trabajados</h2>${silhouette(d.muscles)}
 <p class="pa-muted">Color más intenso = más ejercicios registrados. No mide composición corporal, lesiones ni desarrollo muscular real.</p>
 </section>
 <section class="pa-panel"><h2>Orientación de entrenamiento</h2>
 <div class="pa-coaching-score"><strong>${d.rating}<small>/100</small></strong>
 <div><span>Registro ${esc(d.label)}</span><small>Indicador orientativo de actividad registrada, no certifica nivel profesional.</small></div></div>
 <div class="pa-insight-stats"><span>${d.uniqueDays} días diferentes</span>
 <span>${d.logged} series con cargas</span><span>${d.muscles.length} grupos detectados</span></div>
 <ul>${d.recommendations.map(item=>`<li>${esc(item)}</li>`).join('')}</ul>
 <p class="pa-muted">Valoración provisional calculada únicamente sobre el historial cargado: más datos y una evaluación del entrenador pueden cambiarla.</p>
 </section></div>`;
}
