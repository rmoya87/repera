package dev.repera.domain

/** Port RotationEngine.swift Apple5890215d, no calendar dependence. */
data class RotationPlan(val id:String,val label:String="Mi rotación",val routineIds:List<String> = emptyList(),val nextIndex:Int=0) {
    val nextRoutineId:String? get()=if(routineIds.isEmpty()) null else routineIds[Math.floorMod(nextIndex,routineIds.size)]
    fun advanced():RotationPlan = if(routineIds.isEmpty()) this else copy(nextIndex=(nextIndex+1)%routineIds.size)
    fun moved(from:Int,to:Int):RotationPlan {
        if(from !in routineIds.indices || to !in routineIds.indices) return this
        val ids=routineIds.toMutableList();ids.add(to,ids.removeAt(from))
        return copy(routineIds=ids,nextIndex=minOf(nextIndex,maxOf(0,ids.size-1)))
    }
}
