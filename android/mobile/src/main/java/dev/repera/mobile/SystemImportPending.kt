package dev.repera.mobile

import android.content.Context
import java.io.File

/** Reads and clears system-share pending files written by [SystemShareImport]. */
internal object SystemImportPending {
    private const val PREFS = "repera.system_import"

    data class Gpx(val file: File, val displayName: String)
    data class Board(val file: File)

    fun takeGpx(context: Context): Gpx? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val path = prefs.getString("pendingGpxPath", null) ?: return null
        val name = prefs.getString("pendingGpxName", null) ?: "Ruta GPX"
        prefs.edit().remove("pendingGpxPath").remove("pendingGpxName").apply()
        val file = File(path)
        if (!file.isFile) return null
        return Gpx(file, name)
    }

    fun takeBoard(context: Context): Board? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val path = prefs.getString("pendingBoardPath", null) ?: return null
        prefs.edit().remove("pendingBoardPath").apply()
        val file = File(path)
        if (!file.isFile) return null
        return Board(file)
    }
}
