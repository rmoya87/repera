package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class BusinessProjectionTest {
    @Test fun wireFieldsAndOwnedScheduledProjectionAreSeparateFromPersonalWorkouts() {
        val store=BusinessCenterStore()
        fun row(id:String,client:String,status:String,date:String)=JSONObject().put("id",id).put("org_id","o").put("client_id",client)
            .put("coach_user_id","coach").put("scheduled_date",date).put("title","Plan").put("instructions","").put("status",status).put("prescription",JSONObject().put("schemaVersion",1).put("blocks",JSONArray()))
        val sessions=store.parseProfessionalSessions(JSONArray().put(row("late","mine","scheduled","2026-11-01"))
            .put(row("other","not-mine","scheduled","2026-10-25")).put(row("done","mine","completed","2026-10-24"))
            .put(row("early","mine","scheduled","2026-10-25")))
        assertEquals(listOf("early","late"),store.ownedTraining(sessions,setOf("mine")).map {it.id})
        assertEquals(1,sessions.first().prescription!!.getInt("schemaVersion"))
        assertTrue(store.ownedTraining(sessions,emptySet()).isEmpty())
    }
    @Test fun notificationsDoNotLeakAnotherClientAndKeepBackendOrder() {
        val store=BusinessCenterStore()
        fun notice(id:String,client:String)=JSONObject().put("id",id).put("org_id","o").put("client_id",client)
            .put("title","Aviso").put("body","Mensaje").put("created_at","2026-10-25T20:00:00Z")
        val notices=store.parseNotices(JSONArray().put(notice("one","mine")).put(notice("two","other")).put(notice("three","mine")))
        assertEquals(listOf("one","three"),store.ownedNotices(notices,setOf("mine")).map {it.id})
        assertTrue(store.ownedNotices(notices,emptySet()).isEmpty())
    }
}
