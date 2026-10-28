package dev.repera.domain

import java.text.Normalizer

/**
 * Port de Apple (live main, ff94e6ad) WODHistoryPresentation: nombres de WOD
 * sin distinción de mayúsculas ni grafías de OCR. Solo se resuelven
 * abreviaturas inequívocas, nunca nombres parecidos.
 */
object WODHistoryPresentation {

    /** Nombre oficial para un alias inequívoco (BTT/T2B y variantes OCR), o null. */
    fun officialName(rawName: String): String? {
        // NFKC ≈ precomposedStringWithCompatibilityMapping.
        val compatibility = Normalizer.normalize(rawName, Normalizer.Form.NFKC)
        // «BTt» puede contener una B cirílica (В) o una T griega (Τ). Una
        // transliteración genérica convertiría В en V y «ВΤt» ya no sería BTT:
        // corregir parecidos visuales ANTES. (Apple aplica además una
        // transliteración Latin genérica; aquí el mapa explícito + NFKC cubre
        // los casos verificados por sus tests.)
        val visual = compatibility.map { LOOKALIKES[it] ?: it }.joinToString("")
        val normalized = Normalizer.normalize(visual, Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
            .lowercase()
            .replace(Regex("[^a-z0-9]+"), " ")
            .trim()
        // Compactar únicamente abreviaturas; no hacer búsqueda difusa.
        when (val compact = normalized.replace(" ", "")) {
            "btt" -> return "Burpee to target"
            "t2b", "ttb" -> return "Toes to bar"
            else -> Unit
        }
        return when (normalized) {
            "burpee to target", "burpees to target" -> "Burpee to target"
            "toes to bar", "toes to bars" -> "Toes to bar"
            else -> null
        }
    }

    private val LOOKALIKES: Map<Char, Char> = mapOf(
        'В' to 'B', 'в' to 'b', 'Β' to 'B', 'Ᏼ' to 'B', 'ʙ' to 'b',
        'Т' to 'T', 'т' to 't', 'Τ' to 'T', 'τ' to 't', 'ᴛ' to 't'
    )
}
