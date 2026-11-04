package dev.repera.mobile

/** Stable LazyColumn keys from domain ids. Lazy lists crash on duplicate keys,
 *  so a repeated id (legacy or merged data) gets an occurrence suffix. */
internal object LazyListKeys {
    fun unique(ids: List<String>): List<String> {
        val seen = HashMap<String, Int>()
        return ids.map { id ->
            val occurrence = (seen[id] ?: 0) + 1
            seen[id] = occurrence
            if (occurrence == 1) id else "$id#$occurrence"
        }
    }
}
