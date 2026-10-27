package dev.repera.mobile

/**
 * Pure, Bundle-safe snapshot of the quick-log sheet draft. Apple keeps the same draft in @State, which survives
 * rotation; Android's remember{} lost it (the Activity is recreated). Encoded as a flat list of strings so it can
 * go through rememberSaveable without Parcelable. Process death is covered only to the extent the system saves
 * instance state; Apple does not persist this draft beyond the view either.
 */
data class QuickLogDraft(
 val unit:String,val rows:List<QuickLogRow>,val rowKeys:List<String>,val notes:String,val includeNotes:Boolean,val requestId:String,val owner:String) {
 init {require(rows.size==rowKeys.size)}
 fun encode():List<String> = buildList {
  add("2");add(owner);add(unit);add(notes);add(includeNotes.toString());add(requestId);add(rows.size.toString())
  rows.forEachIndexed {i,r ->
   add(r.quantity.toString());add(r.weightKg?.toString().orEmpty());add(r.durationSeconds?.toString().orEmpty())
   add(r.deficitCm?.toString().orEmpty());add(r.unit);add(rowKeys[i])
  }
 }
 companion object {
  private const val HEADER=7
  private const val STRIDE=6
  /** [expectedOwner] is "account|exercise": a draft saved for another owner is dropped, never adopted. Null when the data is not a well-formed draft: the caller then starts a fresh one instead of guessing. */
  fun decode(data:List<String>?,expectedOwner:String):QuickLogDraft? {
   if(data==null || data.size<HEADER || data[0]!="2" || data[1]!=expectedOwner) return null
   val n=data[6].toIntOrNull() ?: return null
   if(n<0 || n>100 || data.size!=HEADER+n*STRIDE) return null
   val inc=when(data[4]) {"true"->true;"false"->false;else->return null}
   val rows=ArrayList<QuickLogRow>();val keys=ArrayList<String>()
   for(i in 0 until n) {
    val b=HEADER+i*STRIDE
    val q=data[b].toIntOrNull() ?: return null
    val w=if(data[b+1].isEmpty()) null else data[b+1].toDoubleOrNull() ?: return null
    val d=if(data[b+2].isEmpty()) null else data[b+2].toIntOrNull() ?: return null
    val df=if(data[b+3].isEmpty()) null else data[b+3].toIntOrNull() ?: return null
    rows.add(QuickLogRow(q,w,d,df,data[b+4]));keys.add(data[b+5])
   }
   return QuickLogDraft(data[2],rows,keys,data[3],inc,data[5],data[1])
  }
 }
}
