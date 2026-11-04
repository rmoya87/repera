package dev.repera.mobile

/**
 * Navigation-only Assistant / Gemini entry catalog.
 *
 * When Android App Functions (androidx.appfunctions) stabilizes on our minSdk,
 * wire each id to an `@AppFunction`. Until then, capabilities live in
 * `repera_shortcuts.xml` (`OPEN_APP_FEATURE` / `GET_THING`) and deep links below.
 * Never start GPS, Health Connect or set logging from voice / Gemini.
 */
internal object ReperaAppFunctions {
    data class Spec(val id: String, val deepLink: String, val summary: String)

    val catalog: List<Spec> = listOf(
        Spec("open_live", "repera://live", "Abrir Comenzar"),
        Spec("open_today", "repera://today", "Abrir entreno de hoy"),
        Spec("open_timer", "repera://timer", "Abrir temporizador"),
        Spec("open_exercises", "repera://exercises", "Buscar ejercicios"),
        Spec("open_board_scan", "repera://board", "Abrir escáner de pizarra"),
        Spec("import_share", "repera://import", "Procesar importación pendiente")
    )
}
