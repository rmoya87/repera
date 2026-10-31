package dev.repera.wear

/** Reflection helper kept in sync with [WearMainActivity.showSession]. */
internal fun WearMainActivity.testShowSession(
    bytes: ByteArray? = null,
    signedOut: Boolean = false,
    finished: ByteArray? = null,
) {
    val method = WearMainActivity::class.java.getDeclaredMethod(
        "showSession",
        ByteArray::class.java,
        Boolean::class.javaPrimitiveType,
        ByteArray::class.java,
        String::class.java,
        String::class.java,
        String::class.java,
    )
    method.isAccessible = true
    method.invoke(this, bytes, signedOut, finished, null, null, null)
}
