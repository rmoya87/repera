package dev.repera.domain

/**
 * Músculos dibujables en el BodyMap (orden cabeza → pies), alineados con
 * openGym. Port 1:1 de MuscleTaxonomy.swift (iOS).
 */
object MuscleTaxonomy {
    val muscles: List<String> = listOf(
        "trapezius", "deltoids", "chest", "upper-back", "serratus",
        "biceps", "triceps", "forearm",
        "abs", "obliques", "lower-back",
        "gluteal", "quadriceps", "hamstring", "adductors", "hip-flexors",
        "calves", "tibialis"
    )

    val displayNameES: Map<String, String> = mapOf(
        "trapezius" to "Trapecio",
        "deltoids" to "Hombros",
        "chest" to "Pecho",
        "upper-back" to "Espalda alta",
        "serratus" to "Serrato",
        "biceps" to "Bíceps",
        "triceps" to "Tríceps",
        "forearm" to "Antebrazos",
        "abs" to "Abdominales",
        "obliques" to "Oblicuos",
        "lower-back" to "Lumbar",
        "gluteal" to "Glúteos",
        "quadriceps" to "Cuádriceps",
        "hamstring" to "Isquios",
        "adductors" to "Aductores",
        "hip-flexors" to "Flexores de cadera",
        "calves" to "Gemelos",
        "tibialis" to "Tibial"
    )

    /** Partes inertes del SVG (silueta, sin color de carga). */
    val inert: List<String> = listOf(
        "head", "hair", "neck", "hands", "feet", "knees", "ankles"
    )

    private const val secondaryPrimaryWeight = 0.55
    private const val secondaryWeight = 0.35

    private val nonMuscleBodyParts = setOf(
        "full body", "upper arms", "upper legs", "lower legs", "waist",
        "cardio", "shoulders"
    )

    private val alias: Map<String, String?> = mapOf(
        "abs" to "abs", "abdominals" to "abs", "core" to "abs",
        "lower abs" to "abs", "abdomen" to "abs",
        "pectorals" to "chest", "chest" to "chest", "pecho" to "chest",
        "upper chest" to "chest",
        "biceps" to "biceps", "bíceps" to "biceps", "brachialis" to "biceps",
        "triceps" to "triceps", "tríceps" to "triceps",
        "glutes" to "gluteal", "gluteal" to "gluteal", "glúteos" to "gluteal",
        "abductors" to "gluteal",
        "delts" to "deltoids", "deltoids" to "deltoids",
        "shoulders" to "deltoids", "hombros" to "deltoids",
        "rear deltoids" to "deltoids", "rotator cuff" to "deltoids",
        "upper back" to "upper-back", "upper-back" to "upper-back",
        "lats" to "upper-back", "latissimus dorsi" to "upper-back",
        "rhomboids" to "upper-back", "back" to "upper-back",
        "espalda" to "upper-back",
        "calves" to "calves", "gemelos" to "calves", "soleus" to "calves",
        "quads" to "quadriceps", "quadriceps" to "quadriceps",
        "piernas" to "quadriceps",
        "forearms" to "forearm", "forearm" to "forearm",
        "wrists" to "forearm", "antebrazos" to "forearm",
        "grip" to "forearm", "grip muscles" to "forearm",
        "hamstrings" to "hamstring", "hamstring" to "hamstring",
        "isquios" to "hamstring",
        "spine" to "lower-back", "lower back" to "lower-back",
        "lower-back" to "lower-back", "lumbar" to "lower-back",
        "traps" to "trapezius", "trapezius" to "trapezius",
        "trapecio" to "trapezius", "levator scapulae" to "trapezius",
        "adductors" to "adductors", "aductores" to "adductors",
        "groin" to "adductors", "inner thighs" to "adductors",
        "serratus anterior" to "serratus", "serratus" to "serratus",
        "hip flexors" to "hip-flexors", "hip-flexors" to "hip-flexors",
        "obliques" to "obliques", "oblicuos" to "obliques",
        "shins" to "tibialis", "tibialis" to "tibialis",
        "legs" to "quadriceps",
        "ankles" to null, "feet" to null, "hands" to null,
        "ankle stabilizers" to null,
        "cardiovascular system" to null, "cardio" to null,
        "full body" to null, "upper arms" to null, "upper legs" to null,
        "lower legs" to null, "waist" to null
    )

    private val byBodyPartES: Map<String, Map<String, Double>> = mapOf(
        "Pecho" to mapOf("chest" to 1.0),
        "Espalda" to mapOf("upper-back" to 0.75, "lower-back" to 0.25),
        "Hombros" to mapOf("deltoids" to 1.0),
        "Bíceps" to mapOf("biceps" to 1.0),
        "Tríceps" to mapOf("triceps" to 1.0),
        "Piernas" to mapOf("quadriceps" to 0.4, "hamstring" to 0.35, "gluteal" to 0.25),
        "Isquios" to mapOf("hamstring" to 0.7, "gluteal" to 0.3),
        "Glúteos" to mapOf("gluteal" to 1.0),
        "Gemelos" to mapOf("calves" to 0.8, "tibialis" to 0.2),
        "Core" to mapOf("abs" to 0.7, "obliques" to 0.3),
        "Cardio" to emptyMap(),
        "Antebrazos" to mapOf("forearm" to 1.0),
        "Custom" to mapOf(
            "chest" to 0.2, "upper-back" to 0.2, "gluteal" to 0.2,
            "quadriceps" to 0.2, "hamstring" to 0.1, "abs" to 0.1),
        "WOD" to mapOf(
            "chest" to 0.15, "upper-back" to 0.15, "quadriceps" to 0.2,
            "hamstring" to 0.15, "gluteal" to 0.15, "abs" to 0.1,
            "deltoids" to 0.1)
    )

    private val filterGroupES: Map<String, String> = mapOf(
        "chest" to "Pecho",
        "upper-back" to "Espalda",
        "lower-back" to "Espalda",
        "serratus" to "Espalda",
        "trapezius" to "Espalda",
        "deltoids" to "Hombros",
        "biceps" to "Bíceps",
        "triceps" to "Tríceps",
        "forearm" to "Antebrazos",
        "quadriceps" to "Piernas",
        "adductors" to "Piernas",
        "hip-flexors" to "Piernas",
        "hamstring" to "Isquios",
        "gluteal" to "Glúteos",
        "calves" to "Gemelos",
        "tibialis" to "Gemelos",
        "abs" to "Core",
        "obliques" to "Core"
    )

    /** Grupo de biblioteca (filtro ES) según el músculo que más carga. */
    fun libraryMuscleGroup(primaries: List<String>, target: String?): String {
        val candidates = primaries + listOfNotNull(target)
        for (raw in candidates) {
            canonical(raw)?.let { slug -> filterGroupES[slug]?.let { return it } }
            if (byBodyPartES.containsKey(raw)) return raw
        }
        val t = (target ?: "").lowercase()
        if (t.contains("cardio")) return "Cardio"
        return "Custom"
    }

    fun canonical(value: String?): String? {
        val name = value?.lowercase()?.trim() ?: return null
        if (name in muscles) return name
        if (alias.containsKey(name)) return alias[name]
        for ((slug, label) in displayNameES) {
            if (label.lowercase() == name) return slug
        }
        return null
    }

    fun displayName(slug: String): String = displayNameES[slug] ?: slug

    /** Pesos 0…1 por músculo dibujable para un ejercicio del catálogo. */
    fun muscleWeights(
        targetMuscle: String?,
        primaryRegions: List<String>,
        secondaryMuscles: List<String>,
        secondaryRegions: List<String>,
        bodyPart: String?,
        muscleGroup: String?
    ): Map<String, Double> {
        val out = mutableMapOf<String, Double>()
        fun add(raw: String?, w: Double) {
            val slug = canonical(raw) ?: return
            out[slug] = maxOf(out[slug] ?: 0.0, w)
        }
        fun merge(weights: Map<String, Double>, scale: Double = 1.0) {
            for ((slug, w) in weights) {
                if (w > 0) out[slug] = maxOf(out[slug] ?: 0.0, w * scale)
            }
        }

        if (!targetMuscle.isNullOrEmpty()) add(targetMuscle, 1.0)
        for (region in primaryRegions) add(region, 1.0)
        secondaryMuscles.forEachIndexed { idx, secondary ->
            add(secondary, if (idx == 0) secondaryPrimaryWeight else secondaryWeight)
        }
        secondaryRegions.forEachIndexed { idx, region ->
            add(region, if (idx == 0) secondaryPrimaryWeight else secondaryWeight)
        }
        val body = bodyPart?.lowercase()
        if (body != null && body !in nonMuscleBodyParts && canonical(body) != null) {
            add(body, if (out.isEmpty()) 1.0 else 0.25)
        }
        if (out.isEmpty()) {
            add(muscleGroup, 1.0)
        } else {
            add(muscleGroup, 0.2)
        }
        if (out.isEmpty()) byBodyPartES[muscleGroup]?.let { merge(it) }
        if (out.isEmpty()) merge(byBodyPartES["Custom"] ?: mapOf("abs" to 0.5, "upper-back" to 0.5))
        return out.filterValues { it > 0 }
    }
}
