package dev.repera.domain

import java.text.Normalizer

/**
 * Grupo de material para la ordenación de la biblioteca (port 1:1 de
 * ExerciseEquipmentGroup.swift iOS). La fuente de equipo puede ser genérica
 * («Máquina», «Peso corporal»): el nombre del movimiento distingue SkiErg,
 * RowErg, GHD, cajones, etc. Solo afecta a la presentación; nunca altera un
 * Exercise ni su identificador.
 */
object ExerciseEquipmentGroup {

    fun category(name: String, equipment: String?): String {
        val n = normalized(name)
        // Para varios aparatos simultáneos, agrupar por el principal (primer
        // chip) y mostrar todos en la ficha. Evita que «Barra, Banco» se
        // ordene como Banco.
        val primary = (equipment ?: "").split(",", limit = 2).firstOrNull() ?: ""
        val e = normalized(primary)
        fun named(parts: List<String>) = parts.any { n.contains(it) }
        fun equipped(parts: List<String>) = parts.any { e.contains(it) }

        if (named(listOf("skierg", "ski erg", "ski-erg", "esqui de aire",
                "esquis de aire", "esqui ergometro")) ||
            equipped(listOf("skierg", "ski erg", "esqui de aire", "esquis de aire"))) {
            return "SkiErg / esquí de aire"
        }
        if (named(listOf("rowerg", "row erg", "remo maquina", "remoergometro",
                "rowing erg", "rowing machine")) ||
            equipped(listOf("rowerg", "row erg", "remoergometro")) || e == "remo" ||
            (e == "maquina" && named(listOf("remo")))) {
            return "Remoergómetros"
        }
        if (named(listOf("ghd", "glute ham developer", "glute-ham developer")) ||
            equipped(listOf("ghd", "glute ham developer"))) {
            return "GHD"
        }
        if (named(listOf("air bike", "echo bike", "assault bike", "bikeerg",
                "bike erg", "bici estatica", "bicicleta de aire")) ||
            equipped(listOf("air bike", "echo bike", "assault bike", "bikeerg"))) {
            return "Bicicletas y Air Bikes"
        }
        if (named(listOf("cinta / carrera", "treadmill")) ||
            equipped(listOf("cinta de correr", "treadmill"))) {
            return "Cintas de correr"
        }
        if (named(listOf("wall ball", "wallball", "wall-ball",
                "lanzamiento de balon a pared")) ||
            equipped(listOf("wall ball", "wallball"))) {
            return "Wall Balls"
        }
        if (named(listOf("ball slam", "slam ball", "slamball",
                "golpeo de balon al suelo")) ||
            equipped(listOf("slam ball", "slamball"))) {
            return "Slam Balls"
        }
        if (named(listOf("sandbag", "saco de arena", "zancadas con saco")) ||
            equipped(listOf("saco", "sandbag"))) {
            return "Sacos de arena"
        }
        if (named(listOf("sled push", "sled pull", "trineo", "sled drag")) ||
            equipped(listOf("trineo", "sled"))) {
            return "Trineos"
        }
        if (named(listOf("yoke")) || equipped(listOf("yoke", "yugo"))) return "Yugos"
        if (named(listOf("box jump", "box step", "box squat", "box step-up",
                "burpee box", "salto al cajon", "step-up al cajon",
                "burpee al cajon", "box jump over")) ||
            equipped(listOf("cajon", "plyo box", "jump box")) || e == "box" || e == "step") {
            return "Cajones"
        }
        if (named(listOf("double-under", "single-under", "triple-under", "jump rope",
                "dobles de comba", "simples de comba", "triples de comba")) ||
            equipped(listOf("comba", "jump rope", "skipping rope"))) {
            return "Combas"
        }
        if (named(listOf("rope climb", "pegboard rope", "trepa cuerda")) ||
            equipped(listOf("cuerda de trepa", "climbing rope"))) {
            return "Cuerdas de trepa"
        }
        if (named(listOf("anilla", "rings", "ring dip", "ring muscle", "ring row",
                "skin the cat", "false grip hang")) ||
            equipped(listOf("anilla", "gymnastic rings"))) {
            return "Anillas"
        }
        if (named(listOf("pegboard")) || equipped(listOf("pegboard"))) return "Pegboards"
        if (named(listOf("paralela", "parallel bars")) || equipped(listOf("paralela"))) {
            return "Paralelas"
        }
        if (named(listOf("dominada", "pull-up", "pull up", "chin-up", "chin up",
                "chest to bar", "toes to bar", "knees to elbows", "toes to rings",
                "muscle-up barra", "bar muscle up", "hip to bar", "pull-over barra")) ||
            equipped(listOf("barra de dominadas", "barra fija", "pull-up bar",
                "pullup bar"))) {
            return "Barras de dominadas"
        }
        if (equipped(listOf("mancuerna", "dumbbell"))) return "Mancuernas"
        if (equipped(listOf("kettlebell", "pesa rusa"))) return "Kettlebells"
        if (equipped(listOf("banda", "goma", "resistance band", "miniband"))) {
            return "Bandas y gomas"
        }
        if (equipped(listOf("polea", "cable machine"))) return "Poleas"
        if (equipped(listOf("disco", "weight plate"))) return "Discos"
        if (equipped(listOf("barra", "barbell")) || named(listOf("bar facing burpee"))) {
            return "Barras"
        }
        if (equipped(listOf("balon", "medicine ball", "medball"))) {
            return "Balones medicinales"
        }
        if (named(listOf("fondos en banco")) || equipped(listOf("banco", "bench"))) {
            return "Bancos"
        }
        if (equipped(listOf("rueda abdominal", "ab wheel"))) return "Ruedas abdominales"
        if (equipped(listOf("plataforma elevada"))) return "Plataformas de apoyo"
        if (equipped(listOf("pica", "pvc pipe"))) return "Picas"
        if (equipped(listOf("rodillo", "foam roller"))) return "Rodillos"
        if (equipped(listOf("marco de puerta", "door frame"))) return "Marcos de puerta"
        if (named(listOf("wall walk", "wall handstand")) || equipped(listOf("pared", "wall"))) {
            return "Paredes"
        }
        if (equipped(listOf("maquina", "machine", "ergometro"))) return "Máquinas"
        if (equipped(listOf("peso corporal", "bodyweight", "sin material"))) {
            return "Peso corporal"
        }
        if (e.isEmpty()) return "Sin material"
        // Material añadido por el usuario: preservar la etiqueta, nunca descartarlo.
        return equipment?.trim() ?: "Sin material"
    }

    private fun normalized(value: String): String {
        // folding(.diacriticInsensitive, .caseInsensitive) de iOS.
        val decomposed = Normalizer.normalize(value, Normalizer.Form.NFD)
        return decomposed.replace(Regex("\\p{Mn}+"), "").lowercase()
    }
}
