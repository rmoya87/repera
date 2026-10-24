package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AIChangeRequestStoreTest {

    private fun change(operation: String, payload: JSONObject = JSONObject()) =
        AIChangeRequestStore.Change(
            id = "c1", operation = operation, targetId = null,
            expectedUpdatedAt = null, payload = payload, createdAt = null)

    @Test
    fun summariesMatchSpanishCopy() {
        assertEquals("Corregir: Pierna", change("update_workout",
            JSONObject().put("workoutTitle", "Pierna")).summary)
        assertEquals("Eliminar: Pierna", change("delete_workout",
            JSONObject().put("workoutTitle", "Pierna")).summary)
        assertEquals("Añadir ejercicio: Pájaros", change("create_exercise",
            JSONObject().put("name", "Pájaros")).summary)
        assertEquals("Editar ejercicio personalizado: Pájaros",
            change("update_exercise",
                JSONObject().put("name", "Pájaros")).summary)
        assertEquals("Eliminar ejercicio: Pájaros", change("delete_exercise",
            JSONObject().put("name", "Pájaros")).summary)
        assertEquals("Cambio solicitado", change("otra").summary)
    }

    @Test
    fun destructiveFlags() {
        assertTrue(change("delete_workout").isDestructive)
        assertTrue(change("delete_exercise").isDestructive)
        assertFalse(change("update_workout").isDestructive)
        assertFalse(change("create_exercise").isDestructive)
    }

    @Test
    fun parsesPostgresTimestamps() {
        assertNotNull(AIChangeRequestStore.parseInstant("2026-10-24T13:00:00Z"))
        assertNotNull(AIChangeRequestStore.parseInstant("2026-10-24T13:00:00.123456Z"))
        assertNotNull(AIChangeRequestStore.parseInstant("2026-10-24 13:00:00+00"))
        assertNull(AIChangeRequestStore.parseInstant(""))
        assertNull(AIChangeRequestStore.parseInstant(null))
    }
}
