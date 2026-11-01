/** Alcance al reemplazar un entreno de clase (paridad Outlook / edit-occurrence). */

/** Futuras de la misma serie: mismo título, DOW y hora local, desde la base inclusive. */
export function seriesOccurrenceTargets(base,occurrences=[]){
 if(!base)return [];
 const oldStart=new Date(base.starts_at);
 return (occurrences||[]).filter(o=>{
  if(o.org_id&&base.org_id&&o.org_id!==base.org_id)return false;
  if(o.id===base.id)return true;
  if(o.status!=='active'||o.kind!=='class')return false;
  if(o.title!==base.title)return false;
  const s=new Date(o.starts_at);
  if(s<oldStart)return false;
  if(s.getDay()!==oldStart.getDay())return false;
  if(s.getHours()!==oldStart.getHours()||s.getMinutes()!==oldStart.getMinutes())return false;
  return true;
 });
}

/** Clases futuras activas del día (sv-SE YYYY-MM-DD). */
export function dayOccurrenceTargets(day,occurrences=[]){
 if(!day)return [];
 return (occurrences||[]).filter(o=>
  o.kind==='class'&&o.status==='active'&&new Date(o.starts_at)>new Date()
  &&new Date(o.starts_at).toLocaleDateString('sv-SE')===day
 );
}

/**
 * Resuelve IDs según alcance.
 * @param {'one'|'series'|'day'} scope
 */
export function resolveAssignScopeIds({scope='one',baseId='',day='',occurrences=[],selectedIds=[]}={}){
 const base=occurrences.find(o=>o.id===baseId)||occurrences.find(o=>selectedIds.includes(o.id));
 if(scope==='series'&&base)return seriesOccurrenceTargets(base,occurrences).map(o=>o.id);
 if(scope==='day'){
  const d=day||(base?new Date(base.starts_at).toLocaleDateString('sv-SE'):'');
  return dayOccurrenceTargets(d,occurrences).map(o=>o.id);
 }
 if(selectedIds.length)return [...new Set(selectedIds)];
 return base?[base.id]:[];
}
