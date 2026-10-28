package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test

class DiaryCatalogTest {
    private fun routine(id:String,date:String?=null,weekday:Int?=null,title:String=id)=
        RoutineEntry(id,title,true,scheduledDate=date,weekday=weekday)
    @Test fun datedOneOffNeverLeaksIntoPlanOrReusableLibraryEvenWithLegacyWeekday() {
        val dated=routine("dated","2026-10-26",1)
        val weekly=routine("weekly",weekday=2)
        val template=routine("template")
        assertEquals(listOf(weekly),DiaryCatalog.weekly(listOf(dated,weekly,template)))
        assertEquals(listOf(template,weekly),DiaryCatalog.library(listOf(dated,weekly,template)))
    }
    @Test fun weeklyAssignmentRemainsReusableAndOrderingIsSpanish() {
        val tuesday=routine("b",weekday=2,title="Zeta")
        val monday=routine("a",weekday=1,title="Árbol")
        assertEquals(listOf(monday,tuesday),DiaryCatalog.weekly(listOf(tuesday,monday)))
        assertEquals(listOf(monday,tuesday),DiaryCatalog.library(listOf(tuesday,monday)))
    }
    @Test fun malformedWeekdayCannotBecomeScheduleRow() {
        val invalid=routine("bad",weekday=8)
        assertTrue(DiaryCatalog.weekly(listOf(invalid)).isEmpty())
        assertEquals(listOf(invalid),DiaryCatalog.library(listOf(invalid)))
    }
    @Test fun freeTemplateQuotaCountsWeeklyButNotDatedTraining() {
        val entries=listOf(routine("one-off","2026-10-26"),routine("weekly",weekday=1),routine("template"))
        val overview=StateOverview(0,0,3,0,0,null,recentWorkoutTitles=emptyList(),history=emptyList(),
            routineEntries=entries,exerciseEntries=emptyList())
        assertEquals(3,overview.routines)
        assertEquals(2,overview.libraryRoutineCount)
        val policy=dev.repera.domain.monetization.FeatureAccessPolicy(libraryRoutineCount=overview.libraryRoutineCount)
        assertTrue(policy.canCreateLibraryRoutine(true).allowed)
        assertFalse(dev.repera.domain.monetization.FeatureAccessPolicy(libraryRoutineCount=3).canCreateLibraryRoutine(true).allowed)
    }
    @Test fun datedOnListsEverySessionOfTheDateOrderedByTimeTitleId() {
        val d=java.time.LocalDate.of(2026,10,28)
        fun r(id:String,date:String?,time:Int?,title:String)=RoutineEntry(id,title,true,scheduledDate=date,timeMinutes=time)
        val list=listOf(r("c","2026-10-28",null,"A"),r("b","2026-10-28",600,"Z"),r("a","2026-10-28",600,"B"),
            r("x","2026-10-29",100,"Otro dia"),r("t",null,null,"Plantilla"),r("e","2026-10-28T08:00:00Z",null,"A"))
        assertEquals(listOf("a","b","c","e"),DiaryCatalog.datedOn(list,d).map {it.id})
        assertTrue(DiaryCatalog.datedOn(list,java.time.LocalDate.of(2026,10,30)).isEmpty())
    }
}
