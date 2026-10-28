package dev.repera.domain

/** Port of Apple WatchSessionView.blockStarts(in:): first index of each consecutive block run.
 *  A missing id always starts a new entry. */
object WearBlockStarts {
    fun of(blockIds: List<String?>): List<Int> {
        val result = mutableListOf<Int>()
        var last: String? = null
        for (i in blockIds.indices) {
            val id = blockIds[i]
            if (result.isEmpty() || id == null || last == null || id != last) result.add(i)
            last = id
        }
        return result
    }
}
