package dev.repera.mobile

/** Null means invalid text, never an instruction to silently clear an existing target. */
internal fun parsePlannedSetText(reps:String,kg:String,rir:String,id:String?):PlannedSetDraft? {
    val count=reps.toIntOrNull()?.takeIf {it in 1..10000} ?: return null
    val weight=if(kg.isBlank()) null else kg.replace(',','.').toDoubleOrNull()
        ?.takeIf {it.isFinite() && it>=0} ?: return null
    val effort=if(rir.isBlank()) null else rir.replace(',','.').toDoubleOrNull()
        ?.takeIf {it.isFinite() && it>=0} ?: return null
    return PlannedSetDraft(count,weight,effort,id)
}
