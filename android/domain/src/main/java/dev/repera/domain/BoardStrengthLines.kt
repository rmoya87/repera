package dev.repera.domain

/** Bounded subset of BoardImportParser.strengthBlockFromLines: explicit sets x reps,
 * all catalog-matched. Unknown or non-strength text remains on the Lite review path.
 * This is not the full BoardImportParser, nor a migration of existing workouts. */
internal object BoardStrengthLines {
 fun block(lines:List<String>,catalog:List<CatalogExercise>):RoutineBlock? {
  val body=lines.filter {it.trim().length>=2 && it.trim().uppercase(java.util.Locale.ROOT) !in setOf("SETS","REPS","CIRCUITO","CIRCUIT","WARMUP")}
  if(body.isEmpty() || catalog.isEmpty()) return null
  val exercises=body.map {raw ->
   // Percent/RPE annotations are not kg. Leave unsupported intensity on
   // the movement review path instead of falsely creating a load.
   if(Regex("[@#]\\s*>?\\s*\\d+(?:[.,]\\d+)?\\s*%|@\\s*\\d+(?:[.,]\\d+)?\\s*[-–]\\s*\\d+",RegexOption.IGNORE_CASE).containsMatchIn(raw)) return null
   var working=CrossFitGlossary.expand(raw)
   val scheme=Regex("(?<![\\p{L}\\p{N}.,+−–-])(\\d+)\\s*[x×X]\\s*(\\d+)(?![\\p{L}\\p{N}.,×+−–-])").find(working) ?: return null
   if(working.substring(0,scheme.range.first).trimEnd().endsWith("-") ||
      working.substring(0,scheme.range.first).trimEnd().endsWith("–")) return null
   val sets=scheme.groupValues[1].toIntOrNull() ?: return null
   val reps=scheme.groupValues[2].toIntOrNull() ?: return null
   // Bound allocation before review. Do not silently truncate a board.
   if(sets !in 1..200 || reps !in 1..100000) return null
   working=working.removeRange(scheme.range)
   if(working.contains('+') || Regex("\\d+\\s*[x×X]\\s*\\d+").containsMatchIn(working)) return null
   val load=Regex("@\\s*(\\d+(?:[.,]\\d+)?)\\s*(kg|lb)?(?=\\s|$)",RegexOption.IGNORE_CASE).find(working)
   val weight=load?.groupValues?.get(1)?.replace(',','.')?.toDoubleOrNull()
   if(load!=null) {
    if(weight==null || !weight.isFinite() || weight<0) return null
    working=working.removeRange(load.range)
   }
   if(working.contains('@') || working.contains('#')) return null
   val name=working.replace(Regex("^[0-9]+[.)\\-:]?\\s*"),"").trim().trim('-','•','*','|').trim()
   val match=bestMatch(name,catalog) ?: return null
   RoutineExercise(exerciseId=match.id,plannedSets=List(sets) {PlannedSet(targetReps=reps,targetWeightKg=weight)})
  }
  return RoutineBlock.strength(title="Añadir entreno",exercises=exercises)
 }
 /** Full-parser candidate precedence: official exact, editorial alias, any exact,
  * then bounded substring/token fallback with official winner on equal score. */
 internal fun bestMatch(name:String,catalog:List<CatalogExercise>,allowFuzzy:Boolean=true):CatalogExercise? {
  val cleaned=CrossFitGlossary.cleanMovementLabel(name).replace(Regex("\\b(?:t\\s*&\\s*g|touch\\s+and\\s+go|afap|bn|btn|behind\\s+neck|unbroken|uat)\\b",RegexOption.IGNORE_CASE)," ").trim()
  val candidates=listOf(CrossFitGlossary.canonicalName(name),CrossFitGlossary.canonicalName(cleaned),CrossFitGlossary.expand(cleaned),cleaned)
   .map {CrossFitGlossary.normalize(it)}.filter {it.isNotEmpty()}
  for(needle in candidates) catalog.firstOrNull {!it.isCustom && CrossFitGlossary.normalize(it.name)==needle}?.let {return it}
  for(needle in candidates) catalog.firstOrNull {!it.isCustom && !it.isCatalogArchived && it.searchAliases.any {alias ->CrossFitGlossary.normalize(alias)==needle}}?.let {return it}
  for(needle in candidates) catalog.firstOrNull {CrossFitGlossary.normalize(it.name)==needle}?.let {return it}
  if(!allowFuzzy) return null
  var best:CatalogExercise?=null;var bestScore=Int.MAX_VALUE
  for(needle in candidates.filter {it.length>=2}) for(ex in catalog) {
   val hay=CrossFitGlossary.normalize(ex.name);if(hay.length<2) continue
   val hits=needle.split(' ').filter {it.length>=3}.count {hay.contains(it)}
   val tokenCount=needle.split(' ').count {it.length>=3}
   val score=when {
    hay==needle ->0
    hay.contains(needle) || needle.contains(hay) ->kotlin.math.abs(hay.length-needle.length)+1
    hits>=2 || (tokenCount==1 && hits==1) ->50-hits*10
    else ->continue
   }
   if(score<bestScore || (score==bestScore && best?.isCustom==true && !ex.isCustom)) {best=ex;bestScore=score}
  }
  return best
 }
}
