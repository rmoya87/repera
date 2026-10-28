package dev.repera.domain

/** BoardImportParser.parse/parseLine, exposed as a review proposal, never an
 * automatic rewrite of Lite WOD blocks. Allocation is bounded before save. */
object BoardClassicReview {
 data class Draft(val line:BoardImportLine,val name:String,val sets:String,val reps:String,val load:String,val included:Boolean=true) {
  fun resolved(catalog:List<CatalogExercise>):BoardImportLine? {
   val count=sets.toIntOrNull()?.takeIf {it in 1..200} ?: return null
   val repetitions=reps.toIntOrNull()?.takeIf {it in 1..100000} ?: return null
   val weight=if(load.isBlank()) null else load.replace(',','.').toDoubleOrNull()?.takeIf {it.isFinite() && it>=0} ?: return null
   val match=BoardStrengthLines.bestMatch(name,catalog) ?: return null
   return line.copy(matchedExerciseId=match.id,matchedName=match.name,sets=count,reps=repetitions,weightKg=weight,isIncluded=included)
  }
 }
 fun drafts(text:String,catalog:List<CatalogExercise>):List<Draft> = text.lines().map {it.trim()}
  .filter {it.length>1 && !isNoise(it) && !BoardScanLiteParser.isClassicReviewHeader(it) && !BoardScanLiteParser.isQualityAnnotation(it)}
  .map {raw ->
   var working=CrossFitGlossary.expand(raw)
   var load="";var sets="3";var reps="8"
   // Source treats a bare @number as a load in classical strength only.
   // Malformed/ambiguous prescriptions remain visible but cannot be confirmed.
   val at=Regex("@\\s*(\\d+(?:[.,]\\d+)?)\\s*(kg|lb)?(?=\\s|$)",RegexOption.IGNORE_CASE).find(working)
   if(at!=null) {load=at.groupValues[1];working=working.removeRange(at.range)}
   val scheme=Regex("(?<![\\p{L}\\p{N}.,+−–-])(\\d+)\\s*[x×X]\\s*(\\d+)(?![\\p{L}\\p{N}.,×+−–-])").find(working)
   val signedScheme=scheme!=null && working.substring(0,scheme.range.first).trimEnd().let {it.endsWith("-") || it.endsWith("–") || it.endsWith("−")}
   if(scheme!=null) {sets=scheme.groupValues[1];reps=scheme.groupValues[2];working=working.removeRange(scheme.range)}
   val unsafe=signedScheme ||working.contains('@') || working.contains('#') || working.contains('+') ||
    Regex("[\\d.,]+\\s*[x×X]\\s*[-+−–\\d.,]").containsMatchIn(working) ||
    (scheme==null && Regex("[x×X]\\s*[-+−–]?\\d|\\d\\s*[x×X]",RegexOption.IGNORE_CASE).containsMatchIn(working))
   if(unsafe) {sets="";reps=""}
   val name=working.replace(Regex("^[0-9]+[.)\\-:]?\\s*"),"").trim().trim('-','•','*','|').trim().ifBlank {raw}
   val match=if(unsafe) null else BoardStrengthLines.bestMatch(name,catalog)
   val line=BoardImportLine(raw=raw,matchedExerciseId=match?.id,matchedName=match?.name ?: CrossFitGlossary.canonicalName(name),
    sets=sets.toIntOrNull() ?: 3,reps=reps.toIntOrNull() ?: 8,weightKg=load.replace(',','.').toDoubleOrNull())
   Draft(line,name,sets,reps,load)
  }
 fun blocks(drafts:List<Draft>,catalog:List<CatalogExercise>):List<RoutineBlock>? {
  val included=drafts.filter {it.included};if(included.isEmpty()) return null
  val resolved=included.map {it.resolved(catalog) ?: return null}
  return listOf(RoutineBlock.strength(title="Añadir entreno",exercises=resolved.map {line ->
   RoutineExercise(exerciseId=line.matchedExerciseId!!,plannedSets=List(line.sets) {PlannedSet(targetReps=line.reps,targetWeightKg=line.weightKg)})
  }).also {it.wodNotes=included.joinToString("\n") {it.line.raw}})
 }
 private fun isNoise(line:String):Boolean = line.lowercase(java.util.Locale.ROOT) in setOf("sets","reps","warmup","calentamiento","circuito","circuit") ||
  Regex("^[\\d.,]+$").matches(line) || Regex("^\\d{1,2}:\\d{2}$").matches(line)
}
