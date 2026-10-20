// Canonical Repera RoutineBlock-compatible prescription wire contract v1.
// The server revalidates catalog membership and all numeric bounds.
export const WOD_FORMATS = [
 ['amrap','AMRAP'],['emom',"EMOM / Every X'"],['forTime','For Time / RFT'],
 ['tabata','Tabata'],['chipper','Chipper'],['deathBy','Muerte por'],
 ['strength','Fuerza / Skill'],['afap','AFAP'],['ladder','21-15-9 / Ladder'],
 ['partner','Partner / YGIG'],['buyInCashOut','Buy-in / Cash-out'],
 ['roundsForQuality','Rounds for Quality'],['circuit','Circuito'],['maxEffort','Max effort']
];
const uuid=()=>globalThis.crypto?.randomUUID?.() || 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g,c=>{
 const n=Math.floor(Math.random()*16);return (c==='x'?n:(n&3|8)).toString(16);
});
export const escapeHTML=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function makeBlock(kind='strength',id=uuid()){
 if(!['strength','wod'].includes(kind))throw Error('Tipo de bloque inválido');
 return {id,title:kind==='wod'?'WOD':'Bloque de fuerza',kind,exercises:[],movements:[],
  ...(kind==='wod'?{wodFormat:'forTime',rounds:4,timeCapMinutes:12}:{}),
  notes:''};
}
export function makeEntry(kind='strength',source='catalog',id=uuid()){
 if(!['strength','wod'].includes(kind)||!['catalog','free'].includes(source))throw Error('Movimiento inválido');
 return {id,source,catalogKey:null,name:'',...(kind==='strength'?{plannedSets:[makeSet()]}:{reps:10,notes:''})};
}
export function makeSet(id=uuid()){return {id,targetReps:8,targetWeightKg:null,targetRir:null};}
const numeric=(v,label,min,max,optional=false)=>{
 if((v==null||v==='')&&optional)return null;
 const x=Number(v);
 if(!Number.isFinite(x)||x<min||x>max)throw Error(label+' debe estar entre '+min+' y '+max);
 return x;
};
export function buildPrescription(draft,catalog){
 const allowed=new Map(catalog.map(x=>[x.catalogKey,x.name]));
 if(!Array.isArray(draft)||draft.length<1||draft.length>30)throw Error('Añade al menos un bloque (máximo 30)');
 const blocks=draft.map((original,position)=>{
  const b=structuredClone(original);
  if(!['strength','wod'].includes(b.kind)||String(b.title||'').trim().length<2)throw Error('Revisa el título del bloque '+(position+1));
  const field=b.kind==='wod'?'movements':'exercises',other=b.kind==='wod'?'exercises':'movements';
  if(!Array.isArray(b[field])||!b[field].length||b[field].length>50)throw Error('Añade movimientos al bloque '+(position+1));
  b[other]=[];
  b[field]=b[field].map((entry,i)=>{
   const e={id:entry.id||uuid(),source:entry.source,catalogKey:null,name:String(entry.name||'').trim()};
   if(e.source==='catalog'){
    const exact=allowed.get(entry.catalogKey);
    if(!exact)throw Error('Elige un ejercicio válido del catálogo en el bloque '+(position+1));
    e.catalogKey=entry.catalogKey;e.name=exact;
   }else if(e.source!=='free'||e.name.length<2||e.name.length>150)
    throw Error('Escribe un nombre para el ejercicio libre del bloque '+(position+1));
   if(b.kind==='strength'){
    if(!Array.isArray(entry.plannedSets)||!entry.plannedSets.length||entry.plannedSets.length>30)
      throw Error('Indica al menos una serie para '+e.name);
    e.plannedSets=entry.plannedSets.map(set=>({
     id:set.id||uuid(),targetReps:numeric(set.targetReps,'Repeticiones',1,9999),
     targetWeightKg:numeric(set.targetWeightKg,'Carga (kg)',0,2000,true),
     targetRir:numeric(set.targetRir,'RIR',0,10,true)
    }));
   }else{
    e.reps=numeric(entry.reps,'Repeticiones',1,9999);
    e.notes=String(entry.notes||'').slice(0,500);
   }
   return e;
  });
  if(b.kind==='wod'){
   if(!WOD_FORMATS.some(([x])=>x===b.wodFormat))throw Error('Elige un formato WOD válido');
   b.rounds=numeric(b.rounds,'Rondas',1,300,true);
   b.timeCapMinutes=numeric(b.timeCapMinutes,'Tiempo límite',1,300,true);
  }
  b.title=String(b.title).trim();
  return b;
 });
 return {schemaVersion:1,blocks};
}
export function summaryHTML(prescription,legacy='',escape=escapeHTML){
 const blocks=prescription?.schemaVersion===1&&Array.isArray(prescription.blocks)?prescription.blocks:[];
 if(!blocks.length)return '<p>'+escape(legacy||'Sin indicaciones')+'</p>';
 return blocks.map((b,i)=>{
  const names=(b.kind==='strength'?b.exercises:b.movements)||[];
  const format=b.kind==='wod'?(WOD_FORMATS.find(([v])=>v===b.wodFormat)?.[1]||'WOD'):'FUERZA';
  const timing=b.kind==='wod'?[b.rounds?b.rounds+' rondas':'',b.timeCapMinutes?b.timeCapMinutes+' min TC':''].filter(Boolean).join(' · '):'';
  return '<article class="connected-block"><span class="connected-pill">'+escape(format)+'</span> <strong>'+escape((i+1)+'. '+b.title)+'</strong>'+
   (timing?'<small>'+escape(timing)+'</small>':'')+names.map(e=>{
     const detail=b.kind==='strength'?(e.plannedSets||[]).map(s=>s.targetReps+' rep'+(s.targetWeightKg!=null?' · '+s.targetWeightKg+' kg':'')+(s.targetRir!=null?' · RIR '+s.targetRir:'')).join(' / '):[e.reps?e.reps+' rep':'',e.notes].filter(Boolean).join(' · ');
     return '<div class="connected-move"><span>'+escape(e.name)+(e.source==='free'?' <small>· libre</small>':'')+'</span><span>'+escape(detail)+'</span></div>';
   }).join('')+'</article>';
 }).join('');
}
