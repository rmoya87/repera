package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.json.JSONObject

class AIPlansRealtimeListenerTest {

    private val topic = "realtime:public:ai_training_plans:owner_id=eq.uid-1"

    @Test
    fun joinMessageCarriesOwnerFilterAndAccessToken() {
        val message = JSONObject(AIPlansRealtimeListener.joinMessage(topic, "token-abc", 7))
        assertEquals(topic, message.getString("topic"))
        assertEquals("phx_join", message.getString("event"))
        assertEquals("7", message.getString("ref"))
        val payload = message.getJSONObject("payload")
        assertEquals("token-abc", payload.getString("access_token"))
        val change = payload.getJSONObject("config")
            .getJSONArray("postgres_changes").getJSONObject(0)
        assertEquals("INSERT", change.getString("event"))
        assertEquals("ai_training_plans", change.getString("table"))
        assertEquals("owner_id=eq.uid-1", change.getString("filter"))
    }

    @Test
    fun joinAcceptedOnPhxReplyOk() {
        val reply = """{"topic":"$topic","event":"phx_reply","ref":"1",
            "payload":{"status":"ok","response":{}}}"""
        assertEquals(AIPlansRealtimeListener.ServerEvent.JoinAccepted,
            AIPlansRealtimeListener.parseServerEvent(reply, topic))
    }

    @Test
    fun joinRejectedCarriesReason() {
        val reply = """{"topic":"$topic","event":"phx_reply","ref":"1",
            "payload":{"status":"error","response":{"reason":"unauthorized"}}}"""
        val event = AIPlansRealtimeListener.parseServerEvent(reply, topic)
        assertTrue(event is AIPlansRealtimeListener.ServerEvent.JoinRejected)
        assertEquals("unauthorized",
            (event as AIPlansRealtimeListener.ServerEvent.JoinRejected).reason)
    }

    @Test
    fun insertOnExpectedTopicTriggers() {
        val insert = """{"topic":"$topic","event":"postgres_changes","ref":null,
            "payload":{"ids":[1],"data":{"type":"INSERT","table":"ai_training_plans",
            "schema":"public","record":{"id":"p1"},"old_record":{}}}}"""
        assertEquals(AIPlansRealtimeListener.ServerEvent.InsertedPlan,
            AIPlansRealtimeListener.parseServerEvent(insert, topic))
    }

    @Test
    fun insertOnOtherTopicIgnored() {
        val insert = """{"topic":"realtime:public:ai_training_plans:owner_id=eq.otro",
            "event":"postgres_changes","ref":null,
            "payload":{"ids":[1],"data":{"type":"INSERT","table":"ai_training_plans",
            "schema":"public","record":{},"old_record":{}}}}"""
        assertNull(AIPlansRealtimeListener.parseServerEvent(insert, topic))
    }

    @Test
    fun updateAndDeleteEventsIgnored() {
        val update = """{"topic":"$topic","event":"postgres_changes","ref":null,
            "payload":{"ids":[1],"data":{"type":"UPDATE","table":"ai_training_plans",
            "schema":"public","record":{},"old_record":{}}}}"""
        assertNull(AIPlansRealtimeListener.parseServerEvent(update, topic))
    }

    @Test
    fun heartbeatAckOnPhoenixTopic() {
        val ack = """{"topic":"phoenix","event":"phx_reply","ref":"2",
            "payload":{"status":"ok","response":{}}}"""
        assertEquals(AIPlansRealtimeListener.ServerEvent.HeartbeatAck,
            AIPlansRealtimeListener.parseServerEvent(ack, topic))
    }

    @Test
    fun malformedJsonIgnored() {
        assertNull(AIPlansRealtimeListener.parseServerEvent("not-json", topic))
        assertNull(AIPlansRealtimeListener.parseServerEvent("{}", topic))
    }
    @Test fun wrongTableOnMatchingTopicDoesNotTriggerImport() {
        val message=JSONObject().put("topic",topic).put("event","postgres_changes")
            .put("payload",JSONObject().put("data",JSONObject().put("type","INSERT")
                .put("schema","public").put("table","other_table")))
        assertNull(AIPlansRealtimeListener.parseServerEvent(message.toString(),topic))
    }
}
