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

    @Test fun catalogSportsAreAlphabeticalUntilUsedThenRecencyLeads() {
        val virgin = wearHubCarouselItems(null, emptyList())
            .filterIsInstance<WearHubCarouselItem.Sport>()
        assertTrue(virgin.isNotEmpty())
        val titles = virgin.map { it.title }
        val collator = java.text.Collator.getInstance(java.util.Locale.forLanguageTag("es"))
        val withoutOther = virgin.filter { it.sportId != "other" }
        assertTrue(
            withoutOther.zipWithNext().all { (a, b) ->
                collator.compare(a.title, b.title) <= 0
            }
        )
        assertEquals("other", virgin.last().sportId)

        val walk = virgin.first { it.sportId == "walking" }
        val used = wearHubCarouselItems(null, listOf("walking"))
            .filterIsInstance<WearHubCarouselItem.Sport>()
        assertEquals("walking", used.first().sportId)
        assertEquals(walk.title, used.first().title)
        // El resto sigue A–Z tras el reciente.
        val rest = used.drop(1).filter { it.sportId != "other" }
        assertTrue(
            rest.zipWithNext().all { (a, b) ->
                collator.compare(a.title, b.title) <= 0
            }
        )
        assertEquals(titles.size, used.size)
    }

    @Test fun mergeRecentSportsKeepsLocalOrderAndFillsFromPhone() {
        assertEquals(
            listOf("walking", "running"),
            wearMergeRecentSports(listOf("walking"), emptyList())
        )
        assertEquals(
            listOf("cycling"),
            wearMergeRecentSports(emptyList(), listOf("cycling"))
        )
        assertEquals(
            listOf("walking", "running", "cycling"),
            wearMergeRecentSports(
                listOf("walking", "running"),
                listOf("running", "cycling")
            )
        )
    }

    @Test fun todayPlanAlwaysLeadsCarouselBeforeSports() {
        val plan = JSONObject().put("id", "today").put("title", "Fuerza")
        val items = wearHubCarouselItems(plan, listOf("walking", "running"))
        assertTrue(items.first() is WearHubCarouselItem.Plan)
        assertEquals("today", (items.first() as WearHubCarouselItem.Plan).plan.getString("id"))
        val sports = items.filterIsInstance<WearHubCarouselItem.Sport>()
        assertEquals("walking", sports.first().sportId)
        assertEquals("running", sports[1].sportId)
    }
}
