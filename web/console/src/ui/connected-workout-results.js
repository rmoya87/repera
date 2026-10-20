// Returns only the server-approved projection, never GPS, health metrics,
// raw session notes or unconsented workouts.
export function renderSharedWorkoutResults({client,rows=[],esc}) {
 if(!client)return '';
 const sessions=rows.map(row=>{
  const groups=Array.isArray(row.result?.exercises)?row.result.exercises:[];
  const exercises=groups.map(item=>{
   const sets=Array.isArray(item.loggedSets)?item.loggedSets:[];
   const metrics=sets.map(set=>{
    const reps=Number(set.reps);
    const kg=Number(set.weightKg);
    return [Number.isFinite(reps)&&reps>0?reps+' rep':'',
     Number.isFinite(kg)&&kg>0?kg+' kg':''].filter(Boolean).join(' · ');
   }).filter(Boolean).join(' / ');
   return '<div class="connected-move"><strong>'+esc(item.exercise?.name||'Ejercicio')+'</strong><span>'+esc(metrics)+'</span></div>';
  }).join('');
  const wod=Array.isArray(row.result?.wodResults)?row.result.wodResults:[];
  return '<article class="connected-plan"><div class="connected-plan-top"><h3>'+
   esc(row.title||'Entrenamiento')+'</h3><span class="connected-pill">'+
   esc(String(row.finished_at||'').slice(0,10))+'</span></div>'+exercises+
   (wod.length?'<p>'+esc(wod.length+' resultados WOD')+'</p>':'')+
   '</article>';
 }).join('');
 return '<section class="connected-card" style="margin-top:22px"><div class="connected-panel-header"><div><span class="connected-eyebrow">Resultados autorizados</span><h2>'+
   esc(client.name)+'</h2><p>Solo ejercicios y resultados que el deportista ha autorizado compartir. No se muestran ubicaciones, rutas ni Salud.</p></div></div>'+
   (sessions||'<p>No hay resultados compartidos. El deportista puede activar o retirar el permiso desde Ajustes de su app.</p>')+'</section>';
}
