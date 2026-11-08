package dev.repera.domain

/**
 * Etiquetas cortas de material para chips (paridad iOS `ExerciseEquipmentDisplay`).
 * Limpia frases largas del feed remoto / ExerciseDB.
 */
object ExerciseEquipmentDisplay {
    fun chips(from: String?): List<String> {
        if (from.isNullOrBlank()) return emptyList()
        val seen = linkedSetOf<String>()
        val result = mutableListOf<String>()
        for (raw in splitTokens(from)) {
            val label = canonicalize(raw)
            if (label.isEmpty()) continue
            val key = normalize(label)
            if (!seen.add(key)) continue
            result.add(label)
        }
        return result
    }

    fun primary(from: String?): String? = chips(from).firstOrNull()

    fun canonicalize(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return ""
        val key = normalize(trimmed)

        if (key.contains("variante") || key.contains("variant")
            || key.contains("para la ") || key.startsWith("for the ")
        ) {
            val stripped = key
                .replace(Regex("""\b(para la |for the )?variante?\b.*$"""), "")
                .replace(Regex("""\bfor the .+ variant\b.*$"""), "")
                .trim()
            if (stripped.isEmpty()) return ""
            return canonicalize(stripped)
        }

        if (looksLikeMat(key)) return "Colchoneta"
        if (key == "body weight" || key == "bodyweight" || key == "body only"
            || key == "peso corporal" || key == "sin material"
        ) {
            return "Peso corporal"
        }
        if (key.contains("barra de dominadas") || key == "pull-up bar" || key == "pullup bar"
            || key == "barra fija"
        ) {
            return "Barra de dominadas"
        }
        if (key == "abmat" || key == "ab mat") return "AbMat"
        if (key.contains("rueda abdominal") || key.contains("ab wheel")) return "Rueda abdominal"
        if (key == "barbell" || key == "barra") return "Barra"
        if (key.contains("dumbbell") || key.contains("mancuerna")) return "Mancuernas"
        if (key.contains("kettlebell") || key.contains("pesa rusa")) return "Kettlebell"
        if (key.contains("anilla") || key == "rings") return "Anillas"
        if (key.contains("cajon") || key == "box" || key == "plyo box") return "Cajón"
        if (key.contains("banda") || key == "band" || key == "bands") return "Banda"
        if (key.contains("medicine ball") || key == "medball" || key.contains("balon medicinal")) {
            return "Balón medicinal"
        }
        if (key.contains("stability ball") || key.contains("fitball")) return "Fitball"
        if (key.contains("smith")) return "Máquina Smith"
        if (key == "cable" || key.contains("polea")) return "Polea"
        if (key.contains("machine") || key.contains("maquina")) return "Máquina"

        if (trimmed.length <= 28 && !trimmed.contains(" o ", ignoreCase = true)
            && !trimmed.contains(" or ", ignoreCase = true)
        ) {
            return trimmed.replaceFirstChar { it.titlecase() }
        }
        firstClause(key)?.let { return canonicalize(it) }
        return trimmed
    }

    private fun splitTokens(equipment: String): List<String> =
        equipment.replace(';', ',')
            .split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }

    private fun looksLikeMat(key: String): Boolean {
        if (key.contains("colchoneta") || key.contains("superficie acolchada")) return true
        if (key.contains("padded surface") || key.contains("exercise mat")) return true
        if (key == "mat" || key.startsWith("mat ") || key.contains(" mat ")
            || key.contains("yoga mat")
        ) {
            return !key.contains("medball") && !key.contains("medicine")
                && !key.contains("wall ball") && !key.contains("slam")
        }
        return false
    }

    private fun firstClause(key: String): String? {
        for (separator in listOf(" o ", " or ", " / ")) {
            val idx = key.indexOf(separator)
            if (idx > 0) {
                val head = key.substring(0, idx).trim()
                if (head.isNotEmpty()) return head
            }
        }
        return null
    }

    private fun normalize(value: String): String =
        ExerciseAliasSearch.normalize(value)
}
