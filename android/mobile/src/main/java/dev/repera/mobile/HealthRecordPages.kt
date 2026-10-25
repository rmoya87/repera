package dev.repera.mobile

internal data class HealthRecordPage<T>(val records: List<T>, val nextToken: String?)

/** No partial success and no silent cut-off when the provider returns another page. */
internal suspend fun <T> collectHealthPages(read: suspend (String?) -> HealthRecordPage<T>): List<T> {
    val result = mutableListOf<T>()
    val seen = mutableSetOf<String>()
    var token: String? = null
    do {
        val page = read(token)
        result.addAll(page.records)
        token = page.nextToken
        if (token != null) check(seen.add(token)) { "Health Connect repeated a page token" }
    } while (token != null)
    return result
}
