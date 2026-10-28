package dev.repera.domain

import kotlin.math.abs

/**
 * Port 1:1 de ExerciseEquivalence.swift: familia de movimiento, factor de
 * transferencia y coincidencia de identidad de catálogo.
 */
enum class MovementFamily(val label: String) {
    SQUAT("Sentadilla"), HINGE("Bisagra"), PRESS("Press"), PULL("Tirón"),
    OLYMPIC("Olímpico"), JUMP_ROPE("Comba"), ERG("Erg/cardio"), OTHER("Otro")
}

object ExerciseEquivalence {

    /** Clasifica por nombre / equipo / estilo. */
    fun family(exercise: ReviewExercise): MovementFamily {
        val n = normalize(exercise.name)
        val eq = normalize(exercise.equipment ?: "")
        val style = exercise.loggingStyle

        if (style == ExerciseLoggingStyle.REPS_AND_TIME ||
            containsAny(n, "comba", "jump rope", "double under", "single under", "dobles", "simples")) {
            return MovementFamily.JUMP_ROPE
        }
        if (style == ExerciseLoggingStyle.MACHINE_WORK ||
            containsAny(n, "remo", "row", "ski", "bike", "air bike", "echo", "cinta", "run", "correr", "assault") ||
            containsAny(eq, "erg", "remo", "bike", "cinta")) {
            return MovementFamily.ERG
        }
        if (containsAny(n, "snatch", "arrancada", "clean and jerk", "clean & jerk", "envión", "two-part")) {
            return MovementFamily.OLYMPIC
        }
        if (containsAny(n, "thruster", "squat", "sentadilla", "front squat", "back squat", "goblet", "overhead squat", "pistol")) {
            return MovementFamily.SQUAT
        }
        if (containsAny(n, "deadlift", "peso muerto", "rdl", "rumanian", "romanian", "sumo", "good morning", "hip thrust", "swing")) {
            return MovementFamily.HINGE
        }
        // Clean (sin jerk) ≈ hinge/olympic pull — hinge para e1RM de tirón.
        if (matchesWord(n, "clean") || n.contains("cargada")) {
            return MovementFamily.HINGE
        }
        if (containsAny(n, "hspu", "handstand push", "press", "push press", "jerk", "bench", "banca", "fondos", "dip", "shoulder press")) {
            return MovementFamily.PRESS
        }
        if (containsAny(n, "dominad", "pull-up", "pull up", "pullup", "chin-up", "c2b", "chest to bar", "chest-to-bar", "muscle-up", "muscle up", "toes to bar", "ttb", "remo invertido", "ring row")) {
            return MovementFamily.PULL
        }
        return MovementFamily.OTHER
    }

    /** Factor de transferencia al comparar `current` con un set histórico de `prior`. */
    fun transferFactor(current: ReviewExercise, prior: ReviewExercise): Double {
        if (current.id == prior.id) return 1.0
        if (sameName(current.name, prior.name)) return 1.0

        val cf = family(current)
        val pf = family(prior)
        if (cf != pf || cf == MovementFamily.OTHER) return 0.0

        val cn = normalize(current.name)
        val pn = normalize(prior.name)

        // Variantes conocidas dentro de la familia.
        if (cf == MovementFamily.SQUAT) {
            if ((cn.contains("front") && pn.contains("back")) || (cn.contains("back") && pn.contains("front"))) {
                return 0.92
            }
            if (cn.contains("goblet") || pn.contains("goblet")) return 0.88
            if (cn.contains("thruster") || pn.contains("thruster")) return 0.9
            return 0.95
        }
        if (cf == MovementFamily.HINGE) {
            if (cn.contains("sumo") != pn.contains("sumo")) return 0.93
            if (cn.contains("rdl") || pn.contains("rdl") || cn.contains("rumani") || pn.contains("rumani")) {
                return 0.9
            }
            return 0.95
        }
        if (cf == MovementFamily.PRESS) {
            // Un press horizontal (banca) NO es una referencia válida de e1RM
            // para push press/press militar/jerk; incluso entre variantes de
            // hombro cambia la técnica y la transferencia de potencia.
            // Las identidades exactas se devuelven al comienzo del método.
            // Hasta contar con evidencia específica no extrapolamos cargas.
            return 0.0
        }
        if (cf == MovementFamily.PULL) {
            if ((cn.contains("muscle") || pn.contains("muscle")) && !(cn.contains("muscle") && pn.contains("muscle"))) {
                return 0.85
            }
            return 0.95
        }
        if (cf == MovementFamily.OLYMPIC) return 0.9
        if (cf == MovementFamily.JUMP_ROPE || cf == MovementFamily.ERG) return 0.95
        return 0.9
    }

    fun areEquivalent(a: ReviewExercise, b: ReviewExercise): Boolean {
        if (a.id == b.id) return true
        if (sameName(a.name, b.name)) return true
        if (a.loggingStyle != b.loggingStyle) return false
        if (a.loadField != b.loadField) return false
        val fa = family(a)
        val fb = family(b)
        if (fa != fb || fa == MovementFamily.OTHER) return false
        return transferFactor(current = a, prior = b) > 0
    }

    /** Mismo ejercicio de catálogo: id, `catalogId` o nombre canónico. */
    fun matchesCatalogIdentity(a: ReviewExercise, b: ReviewExercise): Boolean {
        if (a.id == b.id) return true
        val ac = a.catalogId
        val bc = b.catalogId
        if (!ac.isNullOrEmpty() && ac == bc) return true
        return sameName(a.name, b.name)
    }

    fun sameName(a: String, b: String): Boolean =
        normalize(SportExerciseNames.canonicalName(a)) == normalize(SportExerciseNames.canonicalName(b))

    // MARK: - Helpers

    /** Swift: folding diacritic/case insensitive + lowercase + trim (sin colapsar signos). */
    private fun normalize(s: String): String =
        java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
            .lowercase()
            .trim()

    private fun containsAny(haystack: String, vararg needles: String): Boolean =
        needles.any { haystack.contains(it) }

    private fun matchesWord(haystack: String, word: String): Boolean =
        Regex("\\b${Regex.escape(word)}\\b").containsMatchIn(haystack)
}
