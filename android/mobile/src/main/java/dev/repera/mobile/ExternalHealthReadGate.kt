package dev.repera.mobile
/** A closed sheet or an A->B->A login cannot receive old health results. */
internal class ExternalHealthReadGate(
 private val owner:String,private val record:String,private val revision:String?
) {
 private var active=true
 fun invalidate() {active=false}
 fun accepts(currentOwner:String,currentRecord:String,currentRevision:String?) =
  active && owner==currentOwner && record==currentRecord && revision==currentRevision
}
