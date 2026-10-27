package dev.repera.domain

import java.text.Normalizer
import java.util.Locale

/** Línea de pizarra interpretada (port de CrossFitGlossary.ParsedMovementLine). */
data class ParsedMovementLine(
    val name: String,
    val reps: Int? = null,
    val repScheme: List<Int>? = null,
    val distanceMeters: Int? = null,
    val calories: Int? = null,
    val weightMaleKg: Double? = null,
    val weightFemaleKg: Double? = null,
    val equipmentNote: String? = null,
    val isRest: Boolean = false,
    val restSeconds: Int? = null
)

/**
 * Port 1:1 de CrossFitGlossary (BoardImportParser.swift de ReperaDomain):
 * glosario de pizarras CrossFit + parseo de líneas de movimiento.
 * La tabla bilingüe de búsqueda (ExerciseSearch.bilingualPhrases en Swift)
 * llega como `searchAliases` con claves ya normalizadas (ExerciseSearchAssets).
 */
object CrossFitGlossary {

    val aliases: Map<String, String> = mapOf(
    /// Abreviatura (normalizada) → nombre canónico en catálogo o texto expandido.
    // Comba
    "du" to "Dobles de comba",
    "dus" to "Dobles de comba",
    "double under" to "Dobles de comba",
    "double unders" to "Dobles de comba",
    "su" to "Simples de comba",
    "sus" to "Simples de comba",
    "single under" to "Simples de comba",
    "single unders" to "Simples de comba",
    "tu" to "Triples de comba",
    "triple unders" to "Triples de comba",
    // Movimientos habituales de pizarra con abreviaturas de posición.
    // R. = reverse: no confundir con walking lunges ni front rack lunges.
    "back squat" to "Sentadilla",
    "high hsq snatch" to "Arrancada colgante completa",
    "high hang squat snatch" to "Arrancada colgante completa",
    "high hang sq snatch" to "Arrancada colgante completa",
    "back rack r lunges" to "Zancadas inversas con barra",
    "back rack r. lunges" to "Zancadas inversas con barra",
    "back rack r. lunge" to "Zancadas inversas con barra",
    "back rack r lunge" to "Zancadas inversas con barra",
    "back rack reverse lunges" to "Zancadas inversas con barra",
    "back rack reverse lunge" to "Zancadas inversas con barra",
    "rear rack reverse lunges" to "Zancadas inversas con barra",
    "barbell reverse lunges" to "Zancadas inversas con barra",
    "power snatches" to "Arrancada de potencia",
    // Cargadas / arrancadas
    "hsc" to "Cargada colgante completa",
    "hang squat clean" to "Cargada colgante completa",
    "high hang squat clean" to "Cargada colgante completa",
    "hhsc" to "Cargada colgante completa",
    "clean pull" to "Tirón de cargada",
    "clean pulls" to "Tirón de cargada",
    "snatch balance" to "Balance de arrancada",
    "hang power clean" to "Hang power clean",
    "hang power cleans" to "Hang power clean",
    "hang power snatch" to "Hang power snatch",
    "front squat" to "Sentadilla frontal",
    "front squats" to "Sentadilla frontal",
    "power clean" to "Cargada de potencia",
    "pc" to "Cargada de potencia",
    "hang clean" to "Cargada colgante",
    "hc" to "Cargada colgante",
    "clean" to "Cargada",
    "squat clean" to "Cargada",
    "squat cleans" to "Cargada",
    "t&g squat clean" to "Cargada",
    "touch and go squat clean" to "Cargada",
    "high hang snatch" to "Arrancada colgante completa",
    "hsq snatch" to "Arrancada colgante completa",
    "hang squat snatch" to "Arrancada colgante completa",
    "back squats" to "Sentadilla",
    "sentadilla trasera" to "Sentadilla",
    "zancadas caminando" to "Walking lunge",
    "lunges" to "Zancadas",
    "lunge" to "Zancadas",
    "reverse lunges back rack" to "Zancadas inversas con barra",
    "power snatch" to "Arrancada de potencia",
    "ps" to "Arrancada de potencia",
    "hang snatch" to "Arrancada colgante",
    "snatch" to "Arrancada",
    "c&j" to "Cargada y envión",
    "cj" to "Cargada y envión",
    "clean and jerk" to "Cargada y envión",
    // Acrónimos de CrossFit, nombre largo EN, español y variantes OCR.
    "gtoh" to "Ground to overhead",
    "g2oh" to "Ground to overhead",
    "g2o" to "Ground to overhead",
    "g to oh" to "Ground to overhead",
    "ground to overhead" to "Ground to overhead",
    "ground-to-overhead" to "Ground to overhead",
    "suelo a overhead" to "Ground to overhead",
    "suelo sobre cabeza" to "Ground to overhead",
    "bmu" to "Muscle-up barra",
    "bar muscle up" to "Muscle-up barra",
    "bar muscle-up" to "Muscle-up barra",
    "bar muscle ups" to "Muscle-up barra",
    "bar muscle-ups" to "Muscle-up barra",
    "muscle up barra" to "Muscle-up barra",
    "akbs" to "Swing americano",
    "akb" to "Swing americano",
    "american kettlebell swings" to "Swing americano",
    "american kb swings" to "Swing americano",
    "swing americano" to "Swing americano",
    "wall balls" to "Wall ball",
    "wallball" to "Wall ball",
    "airbike" to "Air bike",
    "assault bike" to "Air bike",
    "assaultbike" to "Air bike",
    "cal air bike" to "Air bike",
    // Variantes de las pizarras reales: mantener material y estímulo distintos.
    "run" to "Carrera",
    "running" to "Carrera",
    "run meters" to "Carrera",
    "correr" to "Carrera",
    "weighted pull up" to "Dominadas lastradas",
    "weighted pull-up" to "Dominadas lastradas",
    "weighted pull ups" to "Dominadas lastradas",
    "weighted pullups" to "Dominadas lastradas",
    "plyo ring row" to "Remo pliométrico en anillas pies elevados",
    "plyo ring rows" to "Remo pliométrico en anillas pies elevados",
    "plyo ring row feet elevated" to "Remo pliométrico en anillas pies elevados",
    "ring row feet elevated" to "Remo pliométrico en anillas pies elevados",
    "kb goblet alt box step up" to "Step-up al cajón con kettlebell goblet",
    "goblet alt box step up" to "Step-up al cajón con kettlebell goblet",
    "goblet alternating box step up" to "Step-up al cajón con kettlebell goblet",
    "handstand push up" to "HSPU",
    "handstand push-up" to "HSPU",
    "handstand push ups" to "HSPU",
    "kb goblet alternating box step up" to "Step-up al cajón con kettlebell goblet",
    "kettlebell goblet box step up" to "Step-up al cajón con kettlebell goblet",
    "squat snatch" to "Arrancada",
    "squat snatches" to "Arrancada",
    // Press / overhead
    "pp" to "Push press",
    "push press" to "Push press",
    "push press bn" to "Press detrás de nuca",
    "pp bn" to "Press detrás de nuca",
    "bn" to "detrás de nuca",
    "btn" to "detrás de nuca",
    "behind neck" to "detrás de nuca",
    "ohsq" to "Overhead squat",
    "ohs" to "Overhead squat",
    "overhead squat" to "Overhead squat",
    "strict press" to "Strict press",
    "sp" to "Strict press",
    "push jerk" to "Push jerk",
    "push jek" to "Push jerk",
    "push jer" to "Push jerk",
    "pj" to "Push jerk",
    "split jerk" to "Split jerk",
    "bar facing burpee" to "Bar facing burpee",
    "burpee over the bar" to "Bar facing burpee",
    "burpees over the bar" to "Bar facing burpee",
    "burpee over bar" to "Bar facing burpee",
    "bob" to "Bar facing burpee",
    "bobs" to "Bar facing burpee",
    "b.o.b" to "Bar facing burpee",
    "b.o.b." to "Bar facing burpee",
    // OCR a veces pega reps: "8bob" / "8BOB"
    "8bob" to "Bar facing burpee",
    // Condicionamiento
    "wb" to "Wall ball",
    "wall ball" to "Wall ball",
    "wallballs" to "Wall ball",
    "wall ball shot" to "Wall ball",
    "bjo" to "Box jump over",
    // BBJO añade un burpee antes de saltar el cajón: no es BJO.
    "bbjo" to "Burpee box jump over",
    "bbjos" to "Burpee box jump over",
    "burpee box jump over" to "Burpee box jump over",
    "burpee box jump overs" to "Burpee box jump over",
    "burpee box jump-over" to "Burpee box jump over",
    "burpee box jump-overs" to "Burpee box jump over",
    "burpee box jump" to "Burpee box jump over",
    "burpee box jump over(s)" to "Burpee box jump over",
    "kipping ring dip" to "Fondos en anillas kipping",
    "kipping ring dips" to "Fondos en anillas kipping",
    "ring dip" to "Fondos en anillas",
    "ring dips" to "Fondos en anillas",
    "strict ring dips" to "Fondos en anillas",
    "box jump" to "Salto al cajón",
    "bj" to "Salto al cajón",
    "burpee" to "Burpee",
    "bfb" to "Bar facing burpee",
    "ttb" to "Toes to bar",
    "t2b" to "Toes to bar",
    "toes to bar" to "Toes to bar",
    "toes-to-bar" to "Toes to bar",
    "toes to bars" to "Toes to bar",
    "kte" to "Knees to elbows",
    "k2e" to "Knees to elbows",
    "knees to elbows" to "Knees to elbows",
    "ctb" to "Chest to bar",
    "c2b" to "Chest to bar",
    "chest to bar" to "Chest to bar",
    "chest-to-bar" to "Chest to bar",
    "devil press" to "Devil press",
    "devil presses" to "Devil press",
    "db devil press" to "Devil press",
    "ddb devil press" to "Devil press",
    "hspu" to "HSPU",
    "kipping hspu" to "HSPU",
    "kipping hspus" to "HSPU",
    "strict hspu" to "HSPU",
    "hsw" to "Handstand walk",
    "dominadas" to "Dominadas",
    "dominada" to "Dominadas",
    "kipping pull up" to "Dominadas kipping",
    "kipping pull-up" to "Dominadas kipping",
    "kipping pull ups" to "Dominadas kipping",
    "kipping dominadas" to "Dominadas kipping",
    "hang snatch db" to "Snatch mancuerna",
    "db hang snatch" to "Snatch mancuerna",
    "db alt hang snatch" to "Snatch mancuerna",
    "alt hang snatch db" to "Snatch mancuerna",
    "alt hang snatch" to "Arrancada colgante",
    "dumbbell hang snatch" to "Snatch mancuerna",
    "db snatch" to "Snatch mancuerna",
    "dumbbell snatch" to "Snatch mancuerna",
    "snatch mancuerna" to "Snatch mancuerna",
    "snatch db" to "Snatch mancuerna",
    "db thruster" to "Thruster mancuernas",
    "ddb thruster" to "Thruster mancuernas",
    "dumbbell thruster" to "Thruster mancuernas",
    "db clean" to "Clean mancuerna",
    "ddb clean" to "Clean mancuerna",
    "dumbbell clean" to "Clean mancuerna",
    "db hang clean" to "Clean mancuerna",
    "kb thruster" to "Thruster kettlebell",
    "kettlebell thruster" to "Thruster kettlebell",
    "kb snatch" to "Snatch kettlebell",
    "kettlebell snatch" to "Snatch kettlebell",
    "kb clean" to "Clean kettlebell",
    "kettlebell clean" to "Clean kettlebell",
    "db press" to "Press mancuernas",
    "dumbbell press" to "Press mancuernas",
    "db bench" to "Press mancuernas",
    "db bench press" to "Press mancuernas",
    "db row" to "Remo mancuerna",
    "dumbbell row" to "Remo mancuerna",
    "mu" to "Muscle-up barra",
    "bmú" to "Muscle-up barra",
    "rmu" to "Muscle-up anillas",
    "pull up" to "Dominadas",
    "pull ups" to "Dominadas",
    "pull-up" to "Dominadas",
    "pull-ups" to "Dominadas",
    "pullups" to "Dominadas",
    "pu" to "Dominadas",
    "chin up" to "Dominadas supinas",
    "chin ups" to "Dominadas supinas",
    "chin-up" to "Dominadas supinas",
    "chin-ups" to "Dominadas supinas",
    "chinup" to "Dominadas supinas",
    "chinups" to "Dominadas supinas",
    "strict pull up" to "Dominadas estrictas",
    "strict pull-up" to "Dominadas estrictas",
    "strict pull ups" to "Dominadas estrictas",
    "butterfly pull up" to "Dominadas butterfly",
    "butterfly pull-up" to "Dominadas butterfly",
    "ring pull up" to "Dominadas en anillas",
    "ring pull-up" to "Dominadas en anillas",
    "ring pull ups" to "Dominadas en anillas",
    // Variantes concretas (completar glosario; sin duplicar claves ya definidas arriba).
    "walking lunge" to "Walking lunge",
    "walking lunges" to "Walking lunge",
    "front rack lunge" to "Front rack lunge",
    "front rack lunges" to "Front rack lunge",
    "jumping lunge" to "Jumping lunge",
    "jumping lunges" to "Jumping lunge",
    "air squat" to "Air squat",
    "goblet squat" to "Goblet squat",
    "pistol squat" to "Pistol squat",
    "pistol" to "Pistol squat",
    "rdl" to "Peso muerto rumano",
    "romanian deadlift" to "Peso muerto rumano",
    "sumo deadlift" to "Peso muerto sumo",
    "incline bench press" to "Press banca inclinada",
    "decline bench press" to "Press banca declinado",
    "deficit hspu" to "HSPU deficit",
    "hspu deficit" to "HSPU deficit",
    "thruster" to "Thruster",
    "thrusters" to "Thruster",
    "kb swing" to "Swing kettlebell",
    "american swing" to "Swing americano",
    "american kb swing" to "Swing americano",
    "american kettlebell swing" to "Swing americano",
    "kb american swing" to "Swing americano",
    "deadlift" to "Peso muerto",
    "deadlifts" to "Peso muerto",
    "deadlift t&g" to "Peso muerto",
    "deadlift t and g" to "Peso muerto",
    "deadlift touch and go" to "Peso muerto",
    "dl" to "Peso muerto",
    "dl t&g" to "Peso muerto",
    "t&g" to "",
    "touch and go" to "",
    "push presses" to "Push press",
    "cal" to "Air bike",
    "cals" to "Air bike",
    "calorie" to "Air bike",
    "calories" to "Air bike",
    "cal row" to "Air bike",
    "cal ski" to "SkiErg",
    "row" to "Air bike",
    "ski" to "SkiErg",
    "tgu" to "Turkish get-up",
    "ghd" to "GHD sit-up",
    "afap" to "lo más rápido posible",
    // Carrera outdoor reconocida como ejercicio específico; la cinta mantiene su propia ficha.
    "runs" to "Carrera",
    "carrera" to "Carrera",
    "cinta" to "Cinta / carrera",
    "cinta carrera" to "Cinta / carrera",
    "cinta / carrera" to "Cinta / carrera",
    "cinta/carrera" to "Cinta / carrera",
    "jog" to "Cinta / carrera",
    "shuttle run" to "Cinta / carrera",
    // Formatos (para reconocer cabeceras, no ejercicios)
    "amrap" to "AMRAP",
    "emom" to "EMOM",
    "rft" to "RFT",
    "for time" to "For Time",
    "tabata" to "Tabata",
    "chipper" to "Chipper",
    /// Equipo / modalidad en pizarra (no es el nombre del ejercicio).
    /// Fuentes: glosarios CrossFit habituales (DDB=double dumbbell, etc.).
    )

    val equipmentAliases: Map<String, String> = mapOf(
    "ddb" to "Doble mancuerna",
    "double db" to "Doble mancuerna",
    "double dumbbell" to "Doble mancuerna",
    "double dumbbells" to "Doble mancuerna",
    "sdb" to "Mancuerna",
    "single db" to "Mancuerna",
    "single dumbbell" to "Mancuerna",
    "db" to "Mancuerna",
    "dumbbell" to "Mancuerna",
    "dumbbells" to "Mancuerna",
    "dkb" to "Doble kettlebell",
    "double kb" to "Doble kettlebell",
    "double kettlebell" to "Doble kettlebell",
    "skb" to "Kettlebell",
    "single kb" to "Kettlebell",
    "single kettlebell" to "Kettlebell",
    "kb" to "Kettlebell",
    "kettlebell" to "Kettlebell",
    "kettlebells" to "Kettlebell",
    "bb" to "Barra",
    "barbell" to "Barra",
    "ab" to "Air bike",
    "assault bike" to "Air bike",
    "bike erg" to "Air bike",
    "rower" to "Remo",
    "ski erg" to "SkiErg",
    /// Resultado tipado de una línea de movimiento de pizarra.
    /// Parsea «10 T2B», «200M RUN», «5 DDB DEVIL PRESS 20/12,5» → campos tipados.
    )

    /** Folding insensible a diacríticos + puntuación de pizarra a espacios. */
    fun normalize(s: String): String = Normalizer.normalize(s, Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "")
        .lowercase(Locale.ROOT)
        .replace(Regex("[:\\-_/]"), " ")
        .replace(Regex("\\s+"), " ")
        .trim()

    private fun firstIntToken(text: String): Int? =
        Regex("(\\d+)").find(text)?.value?.toIntOrNull()

    fun isAscendingRepRange(scheme: List<Int>?): Boolean {
        if (scheme == null || scheme.size != 2) return false
        val lo = scheme[0]; val hi = scheme[1]
        return lo < hi && (hi - lo) <= 20
    }

    private fun matchLeadingWave(line: String): Pair<List<Int>, String>? {
        val match = Regex("^\\s*(\\d+(?:\\s*[-–]\\s*\\d+)+)\\s+").find(line) ?: return null
        val parts = match.groupValues[1].split(Regex("\\s*[-–]\\s*"))
            .mapNotNull { it.toIntOrNull() }
        if (parts.size < 2) return null
        val rest = line.substring(match.range.last + 1).trim()
        if (rest.isEmpty()) return null
        return parts to rest
    }

    /** Extrae `20/12,5` o `12,5/20` → (mayor=hombre, menor=mujer) + texto restante. */
    fun parseMaleFemaleWeights(text: String): Triple<Double, Double, String>? {
        val match = Regex("#?\\s*(\\d+(?:[.,]\\d+)?)\\s*/\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:kg|lb)?",
            RegexOption.IGNORE_CASE).find(text) ?: return null
        fun clean(part: String): Double? = part.trim()
            .replace("#", "")
            .replace(Regex("(?i)kg"), "")
            .replace(Regex("(?i)lb"), "")
            .replace(",", ".").trim().toDoubleOrNull()
        val a = clean(match.groupValues[1]) ?: return null
        val b = clean(match.groupValues[2]) ?: return null
        val remaining = (text.removeRange(match.range))
            .replace(Regex("\\s+"), " ").trim()
        return Triple(maxOf(a, b), minOf(a, b), remaining)
    }

    /** Expande abreviaturas sueltas y compuestos conocidos en una línea de movimiento. */
    fun expand(raw: String): String {
        var s = raw
        val ordered = aliases.keys.sortedByDescending { it.length }
        for (key in ordered) {
            val value = aliases[key] ?: continue
            val pattern = Regex("\\b" + Regex.escape(key) + "\\b", RegexOption.IGNORE_CASE)
            s = pattern.replace(s, value)
        }
        return s
    }

    /** Nombre canónico para matching de catálogo. */
    fun canonicalName(raw: String, searchAliases: Map<String, String> = emptyMap()): String {
        // Apple (live main, ff94e6ad): BTt/BTT y variantes OCR se resuelven
        // antes de consultar el glosario, incluso sin catálogo descargado.
        WODHistoryPresentation.officialName(raw)?.let { return it }
        val rawNorm = normalize(raw)
        aliases[rawNorm]?.let { return it }
        searchAliases[rawNorm]?.takeIf { it.isNotEmpty() }?.let { return it }
        val ordered = aliases.keys.sortedByDescending { it.length }
        for (key in ordered) {
            val value = aliases[key] ?: continue
            if (key.length < 4 || value.isEmpty()) continue
            val pattern = Regex("\\b" + Regex.escape(key) + "\\b", RegexOption.IGNORE_CASE)
            if (pattern.containsMatchIn(rawNorm)) return value
        }

        val cleaned = cleanMovementLabel(raw)
        val n = normalize(cleaned)
        aliases[n]?.let { return it }
        searchAliases[n]?.takeIf { it.isNotEmpty() }?.let { return it }
        for (key in ordered) {
            val value = aliases[key] ?: continue
            if (key.length < 2 || value.isEmpty()) continue
            if (n == key) return value
            val pattern = Regex("\\b" + Regex.escape(key) + "\\b", RegexOption.IGNORE_CASE)
            if (pattern.containsMatchIn(n)) return value
        }
        val expanded = expand(cleaned)
        val en = normalize(expanded)
        aliases[en]?.let { return it }
        return expanded.trim()
    }

    /** Quita ruido de pizarra: @RIR, @FQ, ondas 4-3-3-2, W.S., DB ALT, etc. */
    fun cleanMovementLabel(raw: String): String {
        var s = raw
        s = Regex("@\\S+(?:\\s+[\\d./\\-–]+)*", RegexOption.IGNORE_CASE).replace(s, " ")
        s = Regex("^\\s*\\d+(?:\\s*[-–]\\s*\\d+)+\\s+").replace(s, "")
        s = Regex("^\\s*\\d+(?:\\s+|(?=[A-Za-zÁÉÍÓÚÑáéíóúñ]))").replace(s, "")
        val noise = listOf(
            "\\bw\\.?\\s*s\\.?\\b", "\\bws\\b", "\\bddb\\b", "\\bsdb\\b", "\\bdkb\\b",
            "\\bskb\\b", "\\bdb\\b", "\\bdumbbells?\\b", "\\bmancuernas?\\b", "\\bkb\\b",
            "\\bkettlebells?\\b", "\\bbb\\b", "\\bbarbell\\b", "\\balt\\b",
            "\\balternat(?:e|ing|as?|os?)?\\b", "\\bweighted\\b", "\\bestrict[oa]?s?\\b",
            "\\bstrikt\\b"
        )
        for (pattern in noise) {
            s = Regex(pattern, RegexOption.IGNORE_CASE).replace(s, " ")
        }
        s = Regex("\\b(kipping|butterfly|strict)\\s+(?=(hspu|pull|dominad|chin|muscle))",
            RegexOption.IGNORE_CASE).replace(s, "")
        return s.replace(Regex("\\s+"), " ").trim().trim('-', '•', '*', '|', ':', '/')
    }

    private enum class EquipmentKind { DUMBBELL, DOUBLE_DUMBBELL, KETTLEBELL, DOUBLE_KETTLEBELL, BARBELL, UNKNOWN }

    private fun equipmentKind(eq: String): EquipmentKind = when {
        eq.contains("doble mancuerna") || eq.contains("double dumbbell") || eq == "ddb" ->
            EquipmentKind.DOUBLE_DUMBBELL
        eq.contains("mancuerna") || eq.contains("dumbbell") || eq == "db" || eq.contains("sdb") ->
            EquipmentKind.DUMBBELL
        eq.contains("doble kettlebell") || eq.contains("double kettlebell") || eq == "dkb" ->
            EquipmentKind.DOUBLE_KETTLEBELL
        eq.contains("kettlebell") || eq == "kb" || eq.contains("skb") ->
            EquipmentKind.KETTLEBELL
        eq.contains("barra") || eq.contains("barbell") || eq == "bb" ->
            EquipmentKind.BARBELL
        else -> EquipmentKind.UNKNOWN
    }

    private fun isSnatchFamily(n: String): Boolean =
        n.contains("arrancada") || n.contains("hang snatch") || n == "snatch" ||
            n.endsWith(" snatch") || n.contains("snatch mancuerna") ||
            n.contains("snatch kettlebell")

    private fun isCleanFamily(n: String): Boolean {
        if (n.contains("envion") || n.contains("jerk") || n.contains("c&j") ||
            n.contains("clean and")) return false
        return n.contains("cargada") || n.contains("hang clean") || n == "clean" ||
            n.endsWith(" clean") || n.contains("clean mancuerna") ||
            n.contains("clean kettlebell")
    }

    /** Redirige al ejercicio de catálogo según equipo (1/2 mancuernas, KB, barra…). */
    fun preferEquipmentVariant(name: String, equipment: String?): String {
        if (equipment.isNullOrEmpty()) return name
        val eq = normalize(equipment)
        val kind = equipmentKind(eq)
        if (kind == EquipmentKind.UNKNOWN) return name
        val n = normalize(name)
        return when (kind) {
            EquipmentKind.DUMBBELL, EquipmentKind.DOUBLE_DUMBBELL -> when {
                n.contains("cargada y envion") || n.contains("clean and jerk") ||
                    n.contains("c&j") -> "Cargada y envión con mancuerna"
                isSnatchFamily(n) -> "Snatch mancuerna"
                isCleanFamily(n) -> "Clean mancuerna"
                n.contains("thruster") -> "Thruster mancuernas"
                n.contains("devil") -> "Devil press"
                n.contains("man maker") || n.contains("manmaker") -> "Man maker"
                n.contains("farmer") -> "Farmer carry"
                n.contains("press banca") || n == "bench press" ||
                    (n.contains("bench") && n.contains("press")) ||
                    n == "press mancuernas" -> "Press mancuernas"
                n.contains("remo") && !n.contains("erg") -> "Remo mancuerna"
                n.contains("dumbbell row") ||
                    (n.endsWith(" row") && !n.contains("rower")) -> "Remo mancuerna"
                n.contains("curl") -> "Curl mancuernas"
                else -> name
            }
            EquipmentKind.KETTLEBELL, EquipmentKind.DOUBLE_KETTLEBELL -> when {
                isSnatchFamily(n) -> "Snatch kettlebell"
                isCleanFamily(n) -> "Clean kettlebell"
                n.contains("thruster") -> "Thruster kettlebell"
                n.contains("swing") ->
                    if (n.contains("american")) "Swing americano" else "Swing kettlebell"
                n.contains("goblet") -> "Goblet squat"
                n.contains("turkish") || n.contains("get up") || n.contains("get-up") ->
                    "Turkish get-up"
                else -> name
            }
            EquipmentKind.BARBELL -> when {
                n.contains("snatch mancuerna") || n.contains("snatch kettlebell") -> "Arrancada"
                n.contains("clean mancuerna") || n.contains("clean kettlebell") -> "Cargada"
                n.contains("thruster mancuern") || n.contains("thruster kettlebell") -> "Thruster"
                n.contains("press mancuern") -> "Press banca"
                else -> name
            }
            EquipmentKind.UNKNOWN -> name
        }
    }

    /** Nombre de catálogo/arte teniendo en cuenta notas de equipo (p. ej. DB → Snatch mancuerna). */
    fun resolveCatalogName(rawName: String, notes: String? = null,
                           searchAliases: Map<String, String> = emptyMap()): String =
        preferEquipmentVariant(canonicalName(rawName, searchAliases), notes)

    /** Parsea una línea de pizarra en un movimiento tipado. */
    fun parseMovementLine(raw: String,
                          searchAliases: Map<String, String> = emptyMap()): ParsedMovementLine {
        var working = raw.trim()
            .replace("’", "'").replace("′", "'").replace("‘", "'")
        working = Regex("(?i)^(ODD|EVEN)\\s*:\\s*").replace(working, "")

        val upper = working.uppercase(Locale.ROOT)
        if (upper.contains("REST") || upper.contains("DESCANSO")) {
            val sec: Int
            val m = firstIntToken(working)
            if (m != null && (upper.contains("'") || upper.contains("MIN"))) {
                sec = m * 60
            } else {
                sec = m ?: 60
            }
            return ParsedMovementLine(name = "REST", isRest = true, restSeconds = sec)
        }

        var scheme: List<Int>? = null
        var reps: Int? = null
        var meters: Int? = null
        var calories: Int? = null
        var male: Double? = null
        var female: Double? = null
        var equipment: String? = null
        var rangeNote: String? = null

        matchLeadingWave(working)?.let { wave ->
            if (isAscendingRepRange(wave.first)) {
                rangeNote = wave.first.joinToString("-")
                reps = wave.first[1]
                working = wave.second
            } else {
                scheme = wave.first
                working = wave.second
            }
        }

        // Objetivo de cardio por sexo: 20/16 CAL* no es 20/16 kg.
        Regex("(?i)^\\s*(\\d+)\\s*/\\s*(\\d+)\\s*CALS?(?:ORIES)?\\b").find(working)?.let { pair ->
            val nums = pair.value.split(Regex("[^0-9]+")).filter { it.isNotEmpty() }
                .mapNotNull { it.toIntOrNull() }
            if (nums.size == 2) {
                return ParsedMovementLine(
                    name = "Air bike",
                    calories = nums[0],
                    equipmentNote = "Cal mujeres: ${nums[1]}" +
                        if (working.contains("*")) " · *" else ""
                )
            }
        }

        Regex("(\\d+)\\s*(?:m|metros?|meters?)\\b", RegexOption.IGNORE_CASE)
            .find(working)?.let { mr ->
                meters = firstIntToken(mr.value)
                working = working.removeRange(mr.range)
            }

        Regex("(\\d+)\\s*cals?\\b", RegexOption.IGNORE_CASE).find(working)?.let { cr ->
            calories = firstIntToken(cr.value)
            working = working.removeRange(cr.range)
        }

        parseMaleFemaleWeights(working)?.let { pair ->
            male = pair.first
            female = pair.second
            working = pair.third
        }

        val equipKeys = equipmentAliases.keys.sortedByDescending { it.length }
        for (key in equipKeys) {
            val pattern = Regex("\\b" + Regex.escape(key) + "\\b", RegexOption.IGNORE_CASE)
            if (pattern.containsMatchIn(working)) {
                equipment = equipmentAliases[key]
                working = pattern.replace(working, " ")
                break
            }
        }

        // Reps al inicio: «10 toes to bar» o pegado OCR «8BOB».
        if (scheme == null && meters == null && calories == null) {
            Regex("^\\s*(\\d+)(?:\\b|(?=[A-Za-zÁÉÍÓÚÑáéíóúñ]))").find(working)?.let { leading ->
                reps = leading.groupValues[1].toIntOrNull()
                working = working.removeRange(leading.range)
            }
        }

        working = cleanMovementLabel(working)
        val canonical = canonicalName(working.ifEmpty { raw }, searchAliases)
        val name = preferEquipmentVariant(canonical.ifEmpty { working }, equipment)

        val technique = mutableListOf<String>()
        if (Regex("\\bALT(?:ERNATING)?\\b", RegexOption.IGNORE_CASE).containsMatchIn(raw)) {
            technique.add("Alternando")
        }
        if (Regex("\\bT\\s*&\\s*G\\b|\\bTOUCH\\s*(?:&|AND|-)?\\s*GO\\b",
                RegexOption.IGNORE_CASE).containsMatchIn(raw)) {
            technique.add("Touch & go")
        }
        val noteParts = (listOfNotNull(rangeNote, equipment) + technique)
            .filter { it.isNotEmpty() }

        return ParsedMovementLine(
            name = name.ifEmpty { working },
            reps = if (meters == null && calories == null && scheme == null) reps else null,
            repScheme = scheme,
            distanceMeters = meters,
            calories = calories,
            weightMaleKg = male,
            weightFemaleKg = female,
            equipmentNote = noteParts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
        )
    }
}
