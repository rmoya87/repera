package dev.repera.wear

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WearMultiplePlansTest {
    @Test fun carouselPreservesTwoIndependentPlansBeforeSports() {
        val first = JSONObject().put("id", "first").put("title", "Fuerza")
        val second = JSONObject().put("id", "second").put("title", "Cardio")
        first.put("_otherTodayPlans", JSONArray().put(second))
        val items = wearHubCarouselItems(first, emptyList())
        assertTrue(items[0] is WearHubCarouselItem.Plan)
        assertTrue(items[1] is WearHubCarouselItem.Plan)
        assertEquals("first", (items[0] as WearHubCarouselItem.Plan).plan.getString("id"))
        assertEquals("second", (items[1] as WearHubCarouselItem.Plan).plan.getString("id"))
    }
}
