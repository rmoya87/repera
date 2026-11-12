package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WorkoutStructureTest {
    @Test fun repeatedAMRAPKeepsBuyInNestedAndRestSeparate() {
        val block=RoutineBlock.wod(WodFormat.AMRAP,"5min AMRAP (x3)")
        block.movements=listOf(
            WODMovement(name="Row",distanceMeters=400),
            WODMovement(name="Pull-up",reps=5),
            WODMovement(name="Push-up",reps=10),
            WODMovement(name="Air squat",reps=15)
        )
        block.wodNotes="""
            Metcon
            5min AMRAP (x3)
            Buy in... 400/320m Row
            Max Rounds of (Cindy):
            5 Pull up
            10 Push up
            15 Air squat
            2min Rest entre AMRAPs
        """.trimIndent()
        WorkoutStructureRecognition.attach(block)
        val phase=block.structure!!.phases.single()
        assertEquals(3,phase.repeatCount)
        assertEquals(300,phase.workSeconds)
        assertEquals(120,phase.restSeconds)
        assertEquals(WorkoutPhaseKind.buyIn,phase.children.first().kind)
        assertEquals(listOf(block.movements.first().id),phase.children.first().movementIDs)
        assertEquals(3,phase.children.last().movementIDs.size)
    }

    @Test fun partnerDoesNotReplaceEMOMAndMaxEffortUsesLoad() {
        val team=RoutineBlock.wod(WodFormat.EMOM,"EMOM 40' (TEAM II)")
        team.movements=listOf(WODMovement(name="Clean and Jerk",reps=60))
        team.wodNotes="60 CLEAN & JERK (60/40)\n(I GO YOU GO)"
        WorkoutStructureRecognition.attach(team)
        assertEquals(WodFormat.EMOM,team.wodFormat)
        assertEquals(WorkoutCollaboration.youGoIGo,team.structure?.collaboration)
        val max=RoutineBlock.wod(WodFormat.MAX_EFFORT,"FIND A HEAVY 1RM")
        WorkoutStructureRecognition.attach(max)
        assertEquals(WorkoutResultMetric.loadKg,max.structure?.resultMetric)
    }

    @Test fun preciseCapsAndDanglingMovementRefsAreSafe() {
        val block=RoutineBlock.wod(WodFormat.FOR_TIME,"FOR TIME (TC 12:30)")
        block.movements=listOf(WODMovement(name="Box Jump",reps=20))
        WorkoutStructureRecognition.attach(block)
        assertEquals(750,block.effectiveTimeCapSeconds)
        val known=block.movements.first().id
        block.structure=WorkoutStructure(phases=listOf(
            WorkoutPhase(kind=WorkoutPhaseKind.main,title="Main",movementIDs=listOf(known,"deleted"))
        ))
        assertEquals(setOf(known),block.structure!!.activeMovementIDs(block))
        assertNull(RoutineBlock.wod(WodFormat.FOR_TIME,"FOR TIME").timeCapSeconds)
    }
}
