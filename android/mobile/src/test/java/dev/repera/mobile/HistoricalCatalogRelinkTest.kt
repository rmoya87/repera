package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class HistoricalCatalogRelinkTest {
    private fun exercise(id: String, name: String, custom: Boolean = false) =
        JSONObject().put("id", id).put("name", name).put("isCustom", custom)
    private fun source(snapshot: JSONObject, vararg catalog: JSONObject): JSONObject {
        val set = JSONObject().put("id", "set").put("reps", 12).put("weightKg", 50)
        val item = JSONObject().put("id", "session-item").put("exercise", snapshot)
            .put("loggedSets", JSONArray().put(set)).put("notes", "keep")
        val workout = JSONObject().put("id", "workout").put("startedAt", "2026-10-25T08:00:00Z")
            .put("score", 42).put("exercises", JSONArray().put(item))
        return JSONObject().put("exercises", JSONArray(catalog.toList()))
            .put("workouts", JSONArray().put(workout))
            .put("activeSession", JSONObject().put("exercises", JSONArray().put(
                JSONObject().put("exercise", JSONObject(snapshot.toString())))))
            .put("updatedAt", "unchanged").put("syncRevision", 8)
    }
    private fun repaired(out: JSONObject) = out.getJSONArray("workouts").getJSONObject(0)
        .getJSONArray("exercises").getJSONObject(0).getJSONObject("exercise")

    @Test fun canonicalBttRepairIsPureAndKeepsAllResultsAndActiveSession() {
        val input = source(exercise("old", "BTt"), exercise("official", "Burpee to target"))
        val before = input.toString()
        val preview = HistoricalCatalogRelink.preview(input)
        assertEquals(before, input.toString())
        assertEquals("official", repaired(preview.state).getString("id"))
        assertEquals(1, preview.changes.size)
        assertEquals(input.getJSONObject("activeSession").toString(), preview.state.getJSONObject("activeSession").toString())
        assertEquals("unchanged", preview.state.getString("updatedAt"))
        assertEquals(8, preview.state.getInt("syncRevision"))
        val expected = JSONObject(before)
        expected.getJSONArray("workouts").getJSONObject(0).getJSONArray("exercises")
            .getJSONObject(0).put("exercise", JSONObject().put("id", "official")
                .put("name", "Burpee to target").put("isCustom", false))
        assertEquals(expected.toString(), preview.state.toString())
        assertTrue(HistoricalCatalogRelink.preview(preview.state).changes.isEmpty())
    }

    @Test fun privateSnapshotsAndPrivateCatalogEntriesAreNeverReplaced() {
        for (customSnapshot in listOf(true, false)) {
            val input = source(exercise("private", "BTt", customSnapshot),
                exercise("private", "BTt", true), exercise("official", "Burpee to target"))
            assertTrue(HistoricalCatalogRelink.preview(input).changes.isEmpty())
        }
        val input = source(exercise("private", "BTt", true), exercise("official", "Burpee to target"))
        assertTrue(HistoricalCatalogRelink.preview(input).changes.isEmpty())
    }

    @Test fun duplicateCanonicalNamesOrDuplicateIdsAreAmbiguousAndNeverChosen() {
        for (catalog in listOf(
            arrayOf(exercise("a", "Toes to bar"), exercise("b", "Toes to bar")),
            arrayOf(exercise("a", "Toes to bar"), exercise("a", "Another"))
        )) {
            val p = HistoricalCatalogRelink.preview(source(exercise("old", "T2B"), *catalog))
            assertTrue(p.changes.isEmpty()); assertEquals(1, p.ambiguous.size)
        }
    }

    @Test fun archivedAndFuzzyNamesDoNotResolve() {
        val archived = exercise("a", "Toes to bar").put("isCatalogArchived", true)
        assertTrue(HistoricalCatalogRelink.preview(source(exercise("old", "T2B"), archived)).changes.isEmpty())
        assertTrue(HistoricalCatalogRelink.preview(source(exercise("old", "Toes to barr"),
            exercise("a", "Toes to bar"))).changes.isEmpty())
    }

    @Test fun exactPublishedAliasRepairsOrphanButConflictsDoNot() {
        val a = exercise("a", "Official row").put("searchAliases", JSONArray().put("Legacy row"))
        val input = source(exercise("missing", "Legacy row"), a)
        assertEquals("a", repaired(HistoricalCatalogRelink.preview(input).state).getString("id"))
        val b = exercise("b", "Other row").put("searchAliases", JSONArray().put("Legacy row"))
        val p = HistoricalCatalogRelink.preview(source(exercise("missing", "Legacy row"), a, b))
        assertTrue(p.changes.isEmpty()); assertEquals(1, p.ambiguous.size)
    }

    @Test fun existingManualChoiceWinsExceptKnownWodAbbreviation() {
        val a = exercise("chosen", "Manual choice")
        val official = exercise("other", "Row").put("searchAliases", JSONArray().put("Legacy"))
        assertTrue(HistoricalCatalogRelink.preview(source(exercise("chosen", "Legacy"), a, official)).changes.isEmpty())
    }

    @Test fun stableCatalogIdentityRepairsOrphanBeforeName() {
        val snap = exercise("old", "Different old name").put("catalogId", "stable")
        val official = exercise("new", "New name").put("catalogId", "stable")
        assertEquals("new", repaired(HistoricalCatalogRelink.preview(source(snap, official)).state).getString("id"))
    }

    @Test fun scheduledWodOnlyChangesReferenceAndKnownAbbreviationLabel() {
        val movement = JSONObject().put("id", "move").put("name", "T2B").put("exerciseId", "old")
            .put("reps", 20).put("notes", "keep").put("explicitPlannedSets", JSONArray().put(JSONObject().put("reps", 10)))
        val input = JSONObject().put("exercises", JSONArray().put(exercise("official", "Toes to bar")))
            .put("routines", JSONArray().put(JSONObject().put("id", "routine").put("date", "keep-date")
                .put("blocks", JSONArray().put(JSONObject().put("kind", "wod")
                    .put("movements", JSONArray().put(movement))))))
        val before = input.toString()
        val p = HistoricalCatalogRelink.preview(input)
        assertEquals(before, input.toString()); assertEquals(1, p.changes.size)
        val expected = JSONObject(before)
        expected.getJSONArray("routines").getJSONObject(0).getJSONArray("blocks").getJSONObject(0)
            .getJSONArray("movements").getJSONObject(0).put("exerciseId", "official").put("name", "Toes to bar")
        assertEquals(expected.toString(), p.state.toString())
        assertTrue(HistoricalCatalogRelink.preview(p.state).changes.isEmpty())
        movement.put("isRest", true)
        assertTrue(HistoricalCatalogRelink.preview(input).changes.isEmpty())
    }
}
