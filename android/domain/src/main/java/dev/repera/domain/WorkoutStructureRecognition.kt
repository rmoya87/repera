package dev.repera.domain

/** Enrich the existing Lite-parser result, never fabricate catalog movements. */
object WorkoutStructureRecognition {
    fun attach(block: RoutineBlock) {
        if (block.structure != null) return
        val source=block.title+"\n"+block.wodNotes.orEmpty()
        val upper=source.uppercase()
        val section:WorkoutSection?=when {
            listOf("WARM UP","WARM-UP","CALENTAMIENTO").any {upper.contains(it)} -> WorkoutSection.warmUp
            listOf("COOL DOWN","COOLDOWN").any {upper.contains(it)} -> WorkoutSection.coolDown
            listOf("ACCESSORY","ACCESORIO").any {upper.contains(it)} -> WorkoutSection.accessory
            listOf("WEIGHTLIFTING","STRENGTH","FUERZA").any {upper.contains(it)} -> WorkoutSection.strength
            listOf("SKILL","GYMNASTICS").any {upper.contains(it)} -> WorkoutSection.skill
            upper.contains("METCON") -> WorkoutSection.metcon
            else -> null
        }
        val collaboration:WorkoutCollaboration?=when {
            listOf("I GO YOU GO","YOU GO I GO","ALTERNANDO","YGIG").any {upper.contains(it)} ->
                WorkoutCollaboration.youGoIGo
            listOf("SYNCHRO","SYNCRO","SYNCHRONIZED").any {upper.contains(it)} ->
                WorkoutCollaboration.synchronized
            listOf("A REPARTIR","TO DIV","SHARED REPS").any {upper.contains(it)} ->
                WorkoutCollaboration.sharedReps
            listOf("JUNTOS","TOGETHER").any {upper.contains(it)} ->
                WorkoutCollaboration.together
            else -> null
        }
        val resultMetric:WorkoutResultMetric? =
            if(block.wodFormat == WODFormat.MAX_EFFORT || (upper.contains("FIND ") && upper.contains("RM")))
                when {
                    upper.contains("MAX CAL") -> WorkoutResultMetric.calories
                    upper.contains("MAX DISTANCE") || upper.contains("MAX METERS") -> WorkoutResultMetric.distanceMeters
                    listOf("1RM","5 RM","MAX LOAD","MAX WEIGHT","FIND A HEAVY").any {upper.contains(it)} ->
                        WorkoutResultMetric.loadKg
                    else -> WorkoutResultMetric.totalReps
                }
            else null
        val ids=block.movements.filterNot {it.isRest}.map {it.id}
        val phases=mutableListOf<WorkoutPhase>()
        val match=Regex("""(?i)(?:\b(\d+)\s*(?:MIN|MN)\s*AMRAP|\bAMRAP\s*(\d+)\s*(?:MIN|MN|['′]))\s*\(\s*[X×]\s*(\d+)\s*\)""").find(source)
        val duration=match?.groupValues?.let {it[1].ifBlank {it[2]}.toIntOrNull()}
        val count=match?.groupValues?.get(3)?.toIntOrNull()
        if(duration!=null && duration in 1..240 && count!=null && count in 2..100) {
            val restMatch=Regex("""(?i)(\d+)\s*(MIN|MN|M\b|['′])\s*REST\s*(?:BETWEEN|ENTRE)""").find(source)
            val rest=restMatch?.groupValues?.get(1)?.toIntOrNull()?.times(60)
            phases.add(WorkoutPhase(kind=WorkoutPhaseKind.work,
                title="AMRAP por intervalos",movementIDs=ids,
                repeatCount=count,workSeconds=duration*60,restSeconds=rest,
                notes=block.wodNotes))
        } else {
            val buyIn=upper.contains("BUY IN") || upper.contains("BUY-IN")
            val cashOut=listOf("BUY OUT","BUY-OUT","CASH OUT","CASH-OUT").any {upper.contains(it)}
            if(buyIn || cashOut) {
                if(buyIn && ids.isNotEmpty())
                    phases.add(WorkoutPhase(kind=WorkoutPhaseKind.buyIn,title="Buy-in",movementIDs=listOf(ids.first())))
                val middle=ids.drop(if(buyIn) 1 else 0)
                    .dropLast(if(cashOut && ids.size>1) 1 else 0)
                if(middle.isNotEmpty())
                    phases.add(WorkoutPhase(kind=WorkoutPhaseKind.main,title="Trabajo principal",movementIDs=middle))
                if(cashOut && ids.isNotEmpty())
                    phases.add(WorkoutPhase(kind=WorkoutPhaseKind.cashOut,title="Cash-out",movementIDs=listOf(ids.last())))
            } else if(block.wodFormat==WODFormat.TABATA) {
                phases.add(WorkoutPhase(kind=WorkoutPhaseKind.work,title="Tabata",movementIDs=ids,
                    repeatCount=block.rounds ?: 8,workSeconds=block.workSeconds ?: 20,
                    restSeconds=block.restSeconds ?: 10))
            } else if(listOf("SUPERSET","TRISET","GIANT SET").any {upper.contains(it)}) {
                phases.add(WorkoutPhase(kind=WorkoutPhaseKind.main,title="Serie combinada",
                    movementIDs=ids,repeatCount=block.rounds,notes=block.wodNotes))
            } else if(collaboration!=null) {
                phases.add(WorkoutPhase(kind=WorkoutPhaseKind.main,title="Trabajo en equipo",
                    movementIDs=ids,notes=block.wodNotes))
            }
        }
        if(section!=null || collaboration!=null || resultMetric!=null || phases.isNotEmpty())
            block.structure=WorkoutStructure(section=section,collaboration=collaboration,
                resultMetric=resultMetric,phases=phases)

        if(block.timeCapSeconds==null) {
            val cap=Regex("""(?i)\b(?:TC|TIME CAP|CAP)\s*[:=]?\s*(\d{1,3}):([0-5]\d)\b""").find(source)
            val minutes=cap?.groupValues?.get(1)?.toIntOrNull()
            val seconds=cap?.groupValues?.get(2)?.toIntOrNull()
            if(minutes!=null && seconds!=null && (minutes>0 || seconds>0))
                block.timeCapSeconds=minutes*60+seconds
        }
    }
}
