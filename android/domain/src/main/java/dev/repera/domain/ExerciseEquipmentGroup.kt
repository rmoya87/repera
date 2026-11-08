package dev.repera.domain

import java.text.Normalizer

/**
 * Grupo de material para la ordenación de la biblioteca (port 1:1 de
 * ExerciseEquipmentGroup.swift iOS).
 *
 * Prioridad: aparato declarado (primer chip) → inferencia por nombre solo si el
 * equipo es genérico (vacío / Peso corporal / Máquina). Evita que «Neumático»
 * caiga en Colchonetas por el substring `mat`, o que Box Squat con Barra vaya
 * a Cajones. Solo presentación; nunca altera Exercise ni id.
 */
object ExerciseEquipmentGroup {

    fun category(name: String, equipment: String?): String {
        val n = normalized(name)
        val primary = (equipment ?: "").split(",", limit = 2).firstOrNull() ?: ""
        val e = normalized(primary)
        fun named(parts: List<String>) = parts.any { n.contains(it) }
        fun equipped(parts: List<String>) = parts.any { e.contains(it) }
        val genericEquipment = e.isEmpty() ||
            equipped(listOf("peso corporal", "bodyweight", "sin material", "maquina", "machine"))

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
            equipped(listOf("air bike", "echo bike", "assault bike", "bikeerg",
                "bicicleta estatica"))) {
            return "Bicicletas y Air Bikes"
        }
        if (named(listOf("cinta / carrera", "treadmill")) ||
            equipped(listOf("cinta de correr", "treadmill"))) {
            return "Cintas de correr"
        }

        // Wall/Slam a veces vienen etiquetados solo como «Balón medicinal».
        if (equipped(listOf("wall ball", "wallball")) ||
            (equipped(listOf("balon", "medicine ball", "medball")) &&
                named(listOf("wall ball", "wallball", "wall-ball",
                    "lanzamiento de balon a pared")))
        ) {
            return "Wall Balls"
        }
        if (equipped(listOf("slam ball", "slamball")) ||
            (equipped(listOf("balon", "medicine ball", "medball")) &&
                named(listOf("ball slam", "slam ball", "slamball",
                    "golpeo de balon al suelo")))
        ) {
            return "Slam Balls"
        }
        if (equipped(listOf("saco", "sandbag"))) return "Sacos de arena"
        if (equipped(listOf("trineo", "sled"))) return "Trineos"
        if (equipped(listOf("yoke", "yugo"))) return "Yugos"
        if (equipped(listOf("cajon", "plyo box", "jump box")) || e == "box" || e == "step") {
            return "Cajones"
        }
        if (equipped(listOf("comba", "jump rope", "skipping rope"))) return "Combas"
        if (equipped(listOf("cuerda de trepa", "climbing rope"))) return "Cuerdas de trepa"
        if (equipped(listOf("cuerda de batalla", "battle rope"))) return "Cuerdas de batalla"
        if (equipped(listOf("anilla", "gymnastic rings"))) return "Anillas"
        if (equipped(listOf("pegboard"))) return "Pegboards"
        if (equipped(listOf("paralela", "parallette"))) return "Paralelas"
        if (equipped(listOf("abmat", "ab mat"))) return "AbMats"
        if (isMatEquipment(e)) return "Colchonetas"
        if (equipped(listOf("barra de dominadas", "barra fija", "pull-up bar", "pullup bar"))) {
            return "Barras de dominadas"
        }
        if (equipped(listOf("mancuerna", "dumbbell"))) return "Mancuernas"
        if (equipped(listOf("kettlebell", "pesa rusa"))) return "Kettlebells"
        if (equipped(listOf("banda", "goma", "resistance band", "miniband"))) {
            return "Bandas y gomas"
        }
        if (equipped(listOf("polea", "cable machine"))) return "Poleas"
        if (equipped(listOf("disco", "weight plate"))) return "Discos"
        if (equipped(listOf("barra", "barbell", "axle", "landmine", "hex", "trap"))) {
            return "Barras"
        }
        if (equipped(listOf("balon", "medicine ball", "medball", "d-ball", "dball"))) {
            return "Balones medicinales"
        }
        if (equipped(listOf("banco", "bench"))) return "Bancos"
        if (equipped(listOf("rueda abdominal", "ab wheel"))) return "Ruedas abdominales"
        if (equipped(listOf("plataforma elevada"))) return "Plataformas de apoyo"
        if (equipped(listOf("pica", "pvc pipe"))) return "Picas"
        if (equipped(listOf("rodillo", "foam roller"))) return "Rodillos"
        if (equipped(listOf("marco de puerta", "door frame"))) return "Marcos de puerta"
        if (equipped(listOf("pared", "wall"))) return "Paredes"
        if (equipped(listOf("neumatico", "tire", "tyre"))) return "Neumáticos"
        if (equipped(listOf("maza", "sledgehammer", "hammer"))) return "Mazas"
        if (equipped(listOf("husafell"))) return "Husafell"
        if (equipped(listOf("atlas", "piedra"))) return "Piedras Atlas"
        if (equipped(listOf("smith"))) return "Máquinas"
        if (equipped(listOf("trx"))) return "TRX"

        if (genericEquipment) {
            if (named(listOf("wall ball", "wallball", "wall-ball",
                    "lanzamiento de balon a pared"))) {
                return "Wall Balls"
            }
            if (named(listOf("ball slam", "slam ball", "slamball",
                    "golpeo de balon al suelo"))) {
                return "Slam Balls"
            }
            if (named(listOf("sandbag", "saco de arena", "zancadas con saco"))) {
                return "Sacos de arena"
            }
            if (named(listOf("sled push", "sled pull", "trineo", "sled drag"))) {
                return "Trineos"
            }
            if (named(listOf("yoke"))) return "Yugos"
            if (named(listOf("box jump", "box step", "box squat", "box step-up",
                    "burpee box", "salto al cajon", "step-up al cajon",
                    "burpee al cajon", "box jump over"))) {
                return "Cajones"
            }
            if (named(listOf("double-under", "single-under", "triple-under", "jump rope",
                    "dobles de comba", "simples de comba", "triples de comba"))) {
                return "Combas"
            }
            if (named(listOf("rope climb", "pegboard rope", "trepa cuerda"))) {
                return "Cuerdas de trepa"
            }
            if (named(listOf("anilla", "rings", "ring dip", "ring muscle", "ring row",
                    "skin the cat", "false grip hang", "german hang",
                    "back lever", "toes to rings"))) {
                return "Anillas"
            }
            if (named(listOf("pegboard"))) return "Pegboards"
            if (named(listOf("paralela", "parallel bars", "parallette"))) {
                return "Paralelas"
            }
            if (named(listOf("ab mat", "abmat"))) return "AbMats"
            if (named(listOf("arch hold", "hollow hold", "hollow rock", "candlestick"))) {
                return "Colchonetas"
            }
            if (named(listOf("dominada", "pull-up", "pull up", "chin-up", "chin up",
                    "chest to bar", "toes to bar", "knees to elbows",
                    "muscle-up barra", "bar muscle up", "hip to bar",
                    "pull-over barra", "dead hang", "hanging knee",
                    "hanging hip", "negative pull"))) {
                return "Barras de dominadas"
            }
            if (named(listOf("fondos en banco"))) return "Bancos"
            if (named(listOf("bar facing burpee"))) return "Barras"
            if (named(listOf("wall walk", "wall handstand", "couch stretch",
                    "gemelo en pared", "soleo en pared", "rodilla a pared"))) {
                return "Paredes"
            }
            if (named(listOf("tire flip", "vuelco de neumatico"))) return "Neumáticos"
        }

        if (equipped(listOf("maquina", "machine", "ergometro"))) return "Máquinas"
        if (equipped(listOf("peso corporal", "bodyweight", "sin material"))) {
            return "Peso corporal"
        }
        if (e.isEmpty()) return "Sin material"
        return equipment?.trim() ?: "Sin material"
    }

    private fun isMatEquipment(e: String): Boolean {
        if (e.contains("colchoneta") || e.contains("yoga mat") || e.contains("exercise mat")) {
            return true
        }
        if (e == "mat") return true
        if (e.startsWith("mat ") || e.endsWith(" mat") || e.contains(" mat ")) return true
        return false
    }

    private fun normalized(value: String): String {
        val decomposed = Normalizer.normalize(value, Normalizer.Form.NFD)
        return decomposed.replace(Regex("\\p{Mn}+"), "").lowercase()
    }
}
