package dev.repera.domain

import java.util.Locale

/**
 * Parser mínimo de pizarra: cabeceras + líneas tipadas vía
 * CrossFitGlossary.parseMovementLine. Port 1:1 de BoardScanLiteParser.swift
 * (ReperaDomain). Sin parser pesado / hilos / IA. Objetivo: nunca bloquear.
 */
object BoardScanLiteParser {

    data class Output(
        val blocks: List<RoutineBlock>,
        val lines: List<BoardImportLine>
    )

    private class Current(
        var header: String,
        val format: WODFormat,
        val cap: Int?,
        val rounds: Int?,
        val interval: Int?,
        val body: MutableList<String>
    )

    fun parse(ocrText: String, catalog: List<CatalogExercise> = emptyList(),
              searchAliases: Map<String, String> = emptyMap()): Output {
        val rawLines = normalizeOCRNoise(ocrText)
            .split('\n')
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        val blocks = mutableListOf<RoutineBlock>()
        var sectionTitle: String? = null
        var pendingSectionFormat:WODFormat?=null
        var intervalDescription: String? = null
        var current: Current? = null

        fun flush() {
            val cur = current ?: return
            val orphanStrength=if(cur.header=="Añadir entreno" || cur.format==WODFormat.STRENGTH)
                BoardStrengthLines.block(cur.body,catalog)?.also {it.title=cur.header} else null
            val structured = orphanStrength ?: structuredIntervalComplex(
                cur.header, cur.body, cur.interval, cur.cap, cur.rounds, catalog, searchAliases
            ) ?: structuredStrength(
                cur.header, cur.body, cur.interval, cur.cap, cur.rounds, catalog
            )
            if (structured != null) {
                blocks.add(structured)
                current = null
                return
            }
            val block = RoutineBlock.wod(
                format = cur.format,
                title = if (cur.header.isEmpty()) cur.format.raw else cur.header
            )
            block.timeCapMinutes = cur.cap
            // El TC pertenece al bloque entero; no crear rondas por defecto.
            block.rounds = if (cur.format == WODFormat.FOR_TIME) cur.rounds
                else (cur.rounds ?: block.rounds)
            if (cur.format == WODFormat.EMOM) {
                block.emomIntervalSeconds = cur.interval ?: 60
            }
            var roundLabel:String?=null
            block.movements = cur.body.filter { line ->
                val upper = line.uppercase(Locale.ROOT)
                !upper.contains("CAP: 4 INTERVALOS") &&
                    !upper.startsWith("REALIZA AMBOS") &&
                    !upper.startsWith("NO TOUCH")
            }.flatMap { raw ->
                // Full parser roundMarker/isFootnote: metadata stays in wodNotes,
                // never becomes a fabricated movement. Round note scopes following rows.
                if(raw.startsWith("*") || raw.startsWith("•")) return@flatMap emptyList()
                Regex("^ROUNDS?\\s*(\\d+)\\s*:?\\s*$",RegexOption.IGNORE_CASE).matchEntire(raw)?.let {round ->
                    roundLabel="Ronda ${round.groupValues[1]}"
                    return@flatMap emptyList()
                }
                val segments=simpleComplexMovements(raw,searchAliases)
                segments.mapNotNull {parsed ->
                    val upperRaw=raw.uppercase(Locale.ROOT)
                    if(cur.format==WODFormat.FOR_TIME && parsed.isRest &&
                        (upperRaw.contains("BTWN") || upperRaw.contains("BETWEEN") || upperRaw.contains("ENTRE RONDAS"))) {
                        block.restBetweenRoundsSeconds=parsed.restSeconds
                        null
                    } else roundLabel?.let {label ->parsed.copy(notes=listOfNotNull(label,parsed.notes).joinToString(" · "))} ?: parsed
                }
            }
            capture("(?i)(\\d+)\\s*MIN\\s*ON.*?(\\d+)\\s*MIN\\s*OFF", cur.header)?.let { values ->
                if (values.size == 2) {
                    val work = values[0].toIntOrNull()
                    val rest = values[1].toIntOrNull()
                    if (work != null && rest != null) {
                        block.workSeconds = work * 60
                        block.restSeconds = rest * 60
                    }
                }
            }
            // 'REST BTWN' describe el descanso *entre* pasadas, no un ejercicio
            // extra al final de la última. Se preserva la anotación original.
            if(cur.format==WODFormat.FOR_TIME && block.restBetweenRoundsSeconds==null) {
                block.movements.firstOrNull {it.isRest}?.let {block.restBetweenRoundsSeconds=it.restSeconds}
            }
            block.wodNotes = (listOf(cur.header) + cur.body).joinToString("\n")
            block.deriveEmomRoundsIfNeeded()
            blocks.add(block)
            current = null
        }

        for (line in rawLines) {
            val upper = line.uppercase(Locale.ROOT)
            val section=sectionLabel(line)
            if(section!=null || upper=="PULLING STRENGTH & POWER") {
                flush()
                sectionTitle=section ?: line
                pendingSectionFormat=if(upper.startsWith("METCON") || upper.startsWith("MET CON") || upper.startsWith("CONDITION") || upper.startsWith("CONDICION")) WODFormat.FOR_TIME else WODFormat.STRENGTH
                continue
            }
            // Clock in the OCR corner and bare numeric noise are not exercises.
            if(Regex("^\\d{1,2}:\\d{2}$").matches(line) || Regex("^[\\d.,]+$").matches(line)) continue
            if (upper.contains("INTERVALOS DE") && upper.contains("ON") &&
                upper.contains("OFF")) {
                intervalDescription = line
                continue
            }
            val header = detectHeader(line)
            if (header != null) {
                flush()
                val title = listOfNotNull(sectionTitle, intervalDescription, header.title)
                    .joinToString(" · ")
                current = Current(title, header.format, header.cap, header.rounds,
                    header.interval, mutableListOf())
                sectionTitle = null
                pendingSectionFormat=null
                intervalDescription = null
            } else if (isQualityAnnotation(line)) {
                // Vision puede separar «EMOM 9' @FOR QUALITY» en @FOR + QUALITY.
                val cur = current
                if (cur != null && !cur.header.uppercase(Locale.ROOT).contains("QUALITY")) {
                    cur.header = if (cur.header.uppercase(Locale.ROOT).endsWith("@FOR"))
                        cur.header + " QUALITY" else cur.header + " · FOR QUALITY"
                }
            } else if (current != null) {
                current!!.body.add(line)
            } else {
                val pendingSection=sectionTitle
                val sectionFormat=pendingSectionFormat ?: WODFormat.CHIPPER
                current = Current(pendingSection ?: "Añadir entreno",sectionFormat,null,null,null,mutableListOf(line))
                sectionTitle=null
                pendingSectionFormat=null
            }
        }
        flush()

        var outBlocks: List<RoutineBlock> = blocks
        if (outBlocks.isEmpty() && rawLines.isNotEmpty()) {
            val block = RoutineBlock.wod(format = WODFormat.CHIPPER, title = "Añadir entreno")
            block.movements = rawLines.map { movement(it, searchAliases) }
            block.wodNotes = ocrText
            outBlocks = listOf(block)
        }

        // Match catálogo por nombre canónico.
        if (catalog.isNotEmpty()) {
            val index = catalogIndex(catalog)
            outBlocks = outBlocks.map { block ->
                block.movements = block.movements.map { move ->
                    if (move.isRest) return@map move
                    val canonical = SportExerciseNames.canonicalName(
                        CrossFitGlossary.canonicalName(move.name, searchAliases)
                    )
                    val keys = listOf(norm(move.name), norm(canonical))
                    val ex = keys.firstNotNullOfOrNull { index[it] }
                    if (ex != null) {
                        move.copy(exerciseId = ex.id, name = ex.name)
                    } else if (canonical != move.name) {
                        move.copy(name = canonical)
                    } else move
                }
                // Un único movimiento, una onda de 4 series y «Every 2'×4»:
                // registrarlo como fuerza editable (no como EMOM de estaciones).
                val titleUpper = block.title.uppercase(Locale.ROOT)
                val interval = block.emomIntervalSeconds
                val move = block.movements.singleOrNull()
                if (block.wodFormat == WODFormat.EMOM &&
                    (titleUpper.startsWith("EVERY ") || titleUpper.startsWith("CADA ")) &&
                    interval != null && interval > 0 &&
                    move != null && !move.isRest &&
                    move.exerciseId != null &&
                    move.repScheme != null && move.repScheme.size == block.rounds) {
                    val rir = rpeMidpointRIR(move.notes)
                    val sets = move.repScheme.map {
                        PlannedSet(targetReps = it, targetWeightKg = move.weightMaleKg,
                            targetRir = rir)
                    }
                    val strength = RoutineBlock.strength(
                        title = block.title,
                        exercises = listOf(RoutineExercise(
                            exerciseId = move.exerciseId, plannedSets = sets))
                    )
                    strength.emomIntervalSeconds = interval
                    strength.timeCapMinutes = block.timeCapMinutes
                    strength.wodNotes = block.wodNotes
                    return@map strength
                }
                block
            }
        }

        val byExerciseID = catalog.associate { it.id to it.name }
        val lines: List<BoardImportLine> = outBlocks.flatMap { block ->
            if (block.kind == RoutineBlockKind.STRENGTH) {
                block.exercises.map { ex ->
                    BoardImportLine(
                        raw = block.wodNotes ?: "",
                        matchedExerciseId = ex.exerciseId,
                        matchedName = byExerciseID[ex.exerciseId],
                        sets = ex.plannedSets.size,
                        reps = ex.plannedSets.firstOrNull()?.targetReps ?: 1
                    )
                }
            } else {
                block.movements.filter { !it.isRest }.map { move ->
                    BoardImportLine(
                        raw = move.summaryLine,
                        matchedExerciseId = move.exerciseId,
                        matchedName = move.name,
                        sets = 1,
                        reps = move.reps ?: move.repScheme?.firstOrNull() ?: 1
                    )
                }
            }
        }

        return Output(blocks = outBlocks, lines = lines)
    }

    // MARK: - Internals

    private class Header(
        val title: String,
        val format: WODFormat,
        val cap: Int?,
        val rounds: Int? = null,
        val interval: Int? = null
    )

    /** Vision a menudo pega tokens (`4RFf`, `8BOB`) o lee T→F (`RFF`). */
    fun normalizeOCRNoise(text: String): String = text
        .replace("’", "'").replace("′", "'").replace("‘", "'")
        .replace("×", "X")
        // 4RFf / 4RFF / 4RFT → "4 RFT"
        .replace(Regex("(\\d+)\\s*RF[TF]\\b", RegexOption.IGNORE_CASE), "$1 RFT")
        // TC12 / TC12? → TC 12
        .replace(Regex("\\bTC\\s*[:=]?\\s*(\\d+)", RegexOption.IGNORE_CASE), "TC $1")
        // 10BBJO / 10BBJ0 (Vision confunde O y 0) → "10 BBJO"
        .replace(Regex("(\\d+)\\s*BBJ[O0]\\b", RegexOption.IGNORE_CASE), "$1 BBJO")
        // 8BOB / 8BFB → "8 BOB"
        .replace(Regex("(\\d+)(BOB|BFB)\\b", RegexOption.IGNORE_CASE), "$1 $2")
        // EVERY2'X4 → EVERY 2' X 4
        .replace(Regex("\\b(EVERY|CADA)\\s*(\\d+)\\s*'?\\s*X\\s*(\\d+)\\b",
            RegexOption.IGNORE_CASE), "$1 $2' X $3")

    /** Metadatos breves de calidad, incluso cuando el OCR corta «@FOR QUALITY». */
    fun isQualityAnnotation(line: String): Boolean {
        val normalized = line.uppercase(Locale.ROOT)
            .trim()
            .trim(' ', '@', ':', '.', '-')
            .replace(Regex("\\s+"), " ")
        return setOf("QUALITY", "FOR QUALITY", "FQ", "RFQ", "FOR").contains(normalized)
    }

    /** BoardImportParser.sectionLabelTitle subset: explicit section prefix.
     * Titles remain visible even without a following timed-format header. */
    private fun sectionLabel(line:String):String? {
        val upper=line.uppercase(Locale.ROOT)
        val labels=listOf("WEIGHTLIFTING","WEIGHT LIFTING","HALTEROFILIA","HALTERO","METCON","MET CON","CONDITIONING","CONDICIONAMIENTO","GYMNASTICS","GIMNASIA","STRENGTH","FUERZA","SKILL","TECH","WOD","WORKOUT")
        val label=labels.sortedByDescending {it.length}.firstOrNull {upper==it || upper.startsWith("$it ") || upper.startsWith("$it:") || upper.startsWith("$it\"") || upper.startsWith("$it“") || upper.startsWith("$it«")} ?: return null
        Regex("[\"“«](.+?)[\"”»]").find(line)?.groupValues?.get(1)?.takeIf {it.isNotBlank()}?.let {return it}
        return line.drop(label.length).trim().trim(':','-','\"').trim().ifBlank {line}
    }

    private fun detectHeader(line: String): Header? {
        val upper = line.uppercase(Locale.ROOT)
            .replace("’", "'").replace("′", "'").replace("×", "X")

        if (Regex("^\\d+\\s+ROUNDS?\\s+(?:FOR\\s+QUALITY|RFQ)\\b").containsMatchIn(upper)) {
            return Header(line, WODFormat.ROUNDS_FOR_QUALITY, null, rounds = firstInt(upper))
        }
        capture("(?i)^EVERY\\s+(\\d+)\\s*S\\s+FOR\\s+(\\d+)\\s*MIN", line)?.let { values ->
            if (values.size == 2) {
                val seconds = values[0].toIntOrNull()
                val minutes = values[1].toIntOrNull()
                if (seconds != null && minutes != null) {
                    val rounds = capture("(?i)\\((\\d+)\\s*(?:SERIES|RONDAS?)\\)", line)
                        ?.firstOrNull()?.toIntOrNull()
                    return Header(line, WODFormat.EMOM, minutes, rounds, seconds)
                }
            }
        }
        // Full parser detectFormatHeader: E2MOM 10' has a 120s cadence,
        // not a movement named E2MOM. Bounded before multiplying minutes.
        Regex("^E\\s*(\\d+)\\s*MOM\\b").find(upper)?.let { match ->
            val minutes=match.groupValues[1].toIntOrNull() ?: return null
            val total=firstInt(upper.removeRange(match.range)) ?: (minutes.toLong()*5).takeIf {it<=Int.MAX_VALUE}?.toInt() ?: return null
            if(minutes !in 1..(Int.MAX_VALUE/60) || total<=0) return null
            return Header(line,WODFormat.EMOM,total,interval=minutes*60)
        }
        // Explicit full-parser headers only. Do not mistake a movement's
        // rep wave (4-3-3-2 PUSH PRESS) for a ladder section.
        if(Regex("^\\d+(?:\\s*[-–]\\s*\\d+){2,}\\s*(?:FOR\\s+TIME|WOD)?$").matches(upper) || upper=="21 15 9")
            return Header(line,WODFormat.LADDER,null)
        if(upper in setOf("PARTNER WOD","PARTNER","YOU GO I GO","YGIG","YDIG"))
            return Header(line,WODFormat.PARTNER,null)
        if(upper in setOf("STRENGTH","FUERZA","TECHNIQUE","TECNICA","TÉCNICA","S&C","SUPERSET","GIANT SET","WARM-UP","WARM UP","CALENTAMIENTO","COOL DOWN","COOLDOWN"))
            return Header(line,WODFormat.STRENGTH,null)
        if (upper.startsWith("EMOM")) {
            val mins = firstInt(upper) ?: 10
            return Header(line, WODFormat.EMOM, mins)
        }
        if (upper.startsWith("AMRAP")) {
            val mins = firstInt(upper) ?: 10
            return Header(line, WODFormat.AMRAP, mins)
        }
        // 4 RFT (TC 12') — también OCR «4RFf(TC 12?» (T leída como F).
        val rftMatch = Regex("^\\d+\\s*RF[TF]\\b").find(upper)
        if (rftMatch != null || upper.startsWith("RFT") || upper.startsWith("RFF") ||
            upper.contains("FOR TIME")) {
            // El número de TC 14' es un límite de TIEMPO del bloque completo.
            val rounds = rftMatch?.let { firstInt(it.value) }
                ?: Regex("^\\s*(\\d+)\\s+ROUNDS?\\b").find(upper)
                    ?.let { firstInt(it.value) }
            val timeCap = Regex("(?:TC|TIME\\s*CAP|CAP)\\s*[:=]?\\s*\\d+").find(upper)
                ?.let { firstInt(it.value) }
            val altCap = capture("(?i)(\\d+)\\s*MIN\\s*CAP", line)
                ?.firstOrNull()?.toIntOrNull()
            val title = if (rftMatch != null)
                line.replace(Regex("(\\d+)\\s*RF[TF]\\b", RegexOption.IGNORE_CASE), "$1 RFT")
            else line
            return Header(title, WODFormat.FOR_TIME, timeCap ?: altCap, rounds)
        }
        if (upper.contains("TABATA")) {
            return Header(line, WODFormat.TABATA, null)
        }
        // Every 90" x 6 (segundos), Every 2' x 4 (minutos), o Every 2 x 4.
        capture("(?i)^(?:EVERY|CADA)\\s+(\\d+)\\s*(\"|''?|S\\b|SEC(?:ONDS?)?\\b|MIN(?:UTES?)?\\b)?\\s*X\\s*(\\d+)\\b",
            line)?.let { fields ->
            if (fields.size == 2 || fields.size == 3) {
                val amount = fields[0].toIntOrNull()
                val count = fields.last().toIntOrNull()
                if (amount != null && count != null && amount > 0 && count > 0 && count <= 200) {
                    val unit = if (fields.size == 3) fields[1].uppercase(Locale.ROOT) else ""
                    val isSeconds = unit == "\"" || unit == "S" || unit.startsWith("SEC")
                    val intervalSeconds = if (isSeconds) amount else amount * 60
                    return Header(
                        line, WODFormat.EMOM,
                        cap = (intervalSeconds * count + 59) / 60,
                        rounds = count, interval = intervalSeconds
                    )
                }
            }
        }
        if (upper.startsWith("EVERY") || upper.startsWith("CADA")) {
            val value = firstInt(upper) ?: 1
            if (upper.contains("SEC") || upper.contains("\"")) {
                return Header(line, WODFormat.EMOM, null, interval = value)
            }
            return Header(line, WODFormat.EMOM, null, interval = value * 60)
        }
        return null
    }

    private fun capture(pattern: String, from: String): List<String>? {
        val regex = Regex(pattern)
        val match = regex.find(from) ?: return null
        return match.groups.drop(1).mapNotNull { it?.value }
    }

    /** Complejo de halterofilia por ronda: cada movimiento se repite en CADA
     * intervalo, p.ej. 90" × 6. No es un circuito de estaciones alternas. */
    private fun structuredIntervalComplex(
        header: String, lines: List<String>, interval: Int?,
        cap: Int?, rounds: Int?, catalog: List<CatalogExercise>,
        searchAliases: Map<String, String>
    ): RoutineBlock? {
        val headerUpper = header.uppercase(Locale.ROOT)
        if (!(headerUpper.startsWith("EVERY") || headerUpper.startsWith("CADA")) ||
            !header.contains("@") ||
            interval == null || interval <= 0 ||
            rounds == null || rounds !in 2..30 ||
            lines.size < 2) return null

        val index = catalogIndex(catalog)
        val rir = rpeMidpointRIR(header)
        val items = mutableListOf<RoutineExercise>()
        for (line in lines) {
            val move = movement(line, searchAliases)
            if (move.isRest || move.reps != 1 || move.repScheme != null ||
                move.distanceMeters != null || move.calories != null) return null
            val canonical = SportExerciseNames.canonicalName(
                CrossFitGlossary.canonicalName(move.name, searchAliases)
            )
            val exercise = index[norm(canonical)] ?: index[norm(move.name)] ?: return null
            val sets = (0 until rounds).map {
                PlannedSet(targetReps = 1, targetWeightKg = move.weightMaleKg, targetRir = rir)
            }
            items.add(RoutineExercise(exerciseId = exercise.id, plannedSets = sets))
        }
        val block = RoutineBlock.strength(title = header, exercises = items)
        block.emomIntervalSeconds = interval
        block.timeCapMinutes = cap
        block.wodNotes = (listOf(header) + lines).joinToString("\n")
        return block
    }

    private fun structuredStrength(
        header: String, lines: List<String>, interval: Int?,
        cap: Int?, rounds: Int?, catalog: List<CatalogExercise>
    ): RoutineBlock? {
        if (lines.any {
                val u = it.uppercase(Locale.ROOT)
                u.contains("SQUAT SNATCH") && u.contains("SETS")
            }) {
            val plan = mutableMapOf<Int, PlannedSet>()
            for (line in lines) {
                val fields = capture(
                    "(?i)SETS?\\s*(\\d+)\\s*[-–]\\s*(\\d+)\\s*:\\s*(\\d+)\\s+SQUAT\\s+SNATCH\\s*#?\\s*>?\\s*(\\d+)\\s*%",
                    line) ?: continue
                if (fields.size != 4) continue
                val start = fields[0].toIntOrNull() ?: continue
                val end = fields[1].toIntOrNull() ?: continue
                val reps = fields[2].toIntOrNull() ?: continue
                val percent = fields[3].toDoubleOrNull() ?: continue
                if (start <= 0 || end > 30 || start > end) continue
                for (index in start..end) {
                    plan[index] = PlannedSet(
                        targetReps = reps, targetPercent1RM = percent,
                        targetPercent1RMIsMinimum = line.contains("#>")
                    )
                }
            }
            val expected = rounds ?: plan.size
            val exercise = catalog.firstOrNull {
                ExerciseEquivalence.sameName(it.name, "Arrancada")
            }
            if (expected <= 0 || plan.size != expected || exercise == null) return null
            val sets = (1..expected).mapNotNull { plan[it] }
            if (sets.size != expected) return null
            val block = RoutineBlock.strength(
                title = header,
                exercises = listOf(RoutineExercise(exerciseId = exercise.id, plannedSets = sets))
            )
            block.emomIntervalSeconds = interval
            block.timeCapMinutes = cap
            block.wodNotes = (listOf(header) + lines).joinToString("\n")
            return block
        }
        val a = lines.firstOrNull { it.uppercase(Locale.ROOT).startsWith("A:") }
        val b = lines.firstOrNull { it.uppercase(Locale.ROOT).startsWith("B:") }
        if (a == null || b == null || rounds == null || rounds <= 0 || rounds > 30) return null
        val left = capture("(?i)^A:\\s*(\\d+)\\s+(.+)$", a)
        val right = capture("(?i)^B:\\s*(\\d+)\\s+(.+)$", b)
        if (left == null || right == null || left.size != 2 || right.size != 2) return null
        val lReps = left[0].toIntOrNull() ?: return null
        val rReps = right[0].toIntOrNull() ?: return null
        val pull = catalog.firstOrNull {
            CrossFitGlossary.normalize(it.name) == CrossFitGlossary.normalize("Dominadas lastradas")
        } ?: return null
        val row = catalog.firstOrNull {
            CrossFitGlossary.normalize(it.name) ==
                CrossFitGlossary.normalize("Remo pliométrico en anillas pies elevados")
        } ?: return null
        val percent = capture("#\\s*(\\d+)\\s*%", left[1])?.firstOrNull()?.toDoubleOrNull()
        val block = RoutineBlock.strength(title = header, exercises = listOf(
            RoutineExercise(exerciseId = pull.id,
                plannedSets = (0 until rounds).map {
                    PlannedSet(targetReps = lReps, targetPercent1RM = percent)
                }),
            RoutineExercise(exerciseId = row.id,
                plannedSets = (0 until rounds).map {
                    PlannedSet(targetReps = rReps)
                })
        ))
        block.emomIntervalSeconds = interval
        block.timeCapMinutes = cap
        block.wodNotes = (listOf(header) + lines).joinToString("\n")
        return block
    }

    /** RPE 6–8 es un rango de esfuerzo: punto medio RPE 7 (≈ RIR 3) editable. */
    private fun rpeMidpointRIR(notes: String?): Double? {
        if (notes == null) return null
        val match = Regex("(?:RPE|@)\\s*(\\d+(?:[.,]\\d+)?)\\s*[-–]\\s*(\\d+(?:[.,]\\d+)?)")
            .find(notes) ?: return null
        val numbers = match.value.split(Regex("[^0-9.,]+"))
            .mapNotNull { it.replace(",", ".").toDoubleOrNull() }
        if (numbers.size != 2) return null
        return Effort.toRIR((numbers[0] + numbers[1]) / 2, "rpe")
    }

    /** Full-parser independently quantified unloaded complex subset. Parent multiplier
     * is a note, never inferred reps/sets. Waves/shared loads remain on review path. */
    private fun simpleComplexMovements(raw:String,aliases:Map<String,String>):List<WODMovement> {
        val multiplierMatch=Regex("^(\\d+)\\s*[x×X]\\s*").find(raw)
        val multiplier=multiplierMatch?.groupValues?.get(1)?.toIntOrNull()
        if(multiplierMatch!=null && (multiplier==null || multiplier !in 1..200)) return listOf(movement(raw,aliases))
        val body=if(multiplierMatch!=null) raw.removeRange(multiplierMatch.range) else raw
        val parts=body.split(Regex("\\s*\\+\\s*")).map {it.trim()}.filter {it.isNotEmpty()}
        val explicit=Regex("^\\d+\\s+[^0-9].*")
        if(parts.size<2 || parts.any {!explicit.matches(it)} ||
            raw.contains('/') || raw.contains('@') || raw.contains('#') ||
            Regex("\\b(?:kg|kgs|lb|lbs)\\b",RegexOption.IGNORE_CASE).containsMatchIn(raw) ||
            Regex("^\\d+\\s*[-–]").containsMatchIn(body)) return listOf(movement(raw,aliases))
        return parts.mapIndexed {index,part ->
            val parsed=movement(part,aliases)
            parsed.copy(notes=listOfNotNull("Parte ${index+1}/${parts.size}",multiplier?.let {"Complejo ×$it"},parsed.notes).joinToString(" · "))
        }
    }

    private fun movement(line: String, searchAliases: Map<String, String>): WODMovement {
        var working = line
        val notes = mutableListOf<String>()
        Regex("^SETS?\\s+(\\d+)\\s*[-–]\\s*(\\d+)\\s*:\\s*",RegexOption.IGNORE_CASE).find(working)?.let {range ->
            notes.add("Series ${range.groupValues[1]}-${range.groupValues[2]}")
            working=working.removeRange(range.range)
        }
        Regex("[#@]\\s*(>?)(\\d+)\\s*%").find(working)?.let {percent ->
            notes.add("${percent.groupValues[1]}${percent.groupValues[2]}%")
            working=working.removeRange(percent.range)
        }
        Regex("@\\s*\\d+(?:[.,]\\d+)?\\s*[-–]\\s*\\d+(?:[.,]\\d+)?").find(working)?.let { rpe ->
            notes.add("RPE " + rpe.value.replace("@", "").trim())
            working = working.removeRange(rpe.range)
        }
        // Alternativas de escala "3 BMU / 6 C2B / 9 Pull-ups" o "40 DU / 80 SU".
        // El slash con espacios NO representa carga H/M.
        var scaleAlternative: String? = null
        val caloriePair = Regex("^\\s*\\d+\\s*/\\s*\\d+\\s*CALS?(?:ORIES)?\\b",
            RegexOption.IGNORE_CASE).containsMatchIn(working)
        // Apple 3432a1a9: «20 / 16 CAL» no es escala. Tampoco
        // «20m SLED PUSH 100 / 70 KG» ni «FARMER CARRY 24 / 16»: son cargas
        // H/M aunque el OCR añada espacios.
        val weightPair = Regex("\\d+(?:[.,]\\d+)?\\s*/\\s*\\d+(?:[.,]\\d+)?\\s*(?:kg|lbs?)?\\s*$",
            RegexOption.IGNORE_CASE).containsMatchIn(working)
        val alternatives = if (caloriePair || weightPair) listOf(working) else working.split(" / ")
        if (alternatives.size >= 2) {
            working = alternatives[0].trim()
            scaleAlternative = alternatives.drop(1)
                .joinToString(" / ") { CrossFitGlossary.expand(it.trim()) }
        }
        val parsed = CrossFitGlossary.parseMovementLine(working, searchAliases)
        if (parsed.isRest) {
            return WODMovement(name = "REST", isRest = true, restSeconds = parsed.restSeconds)
        }
        val allNotes = notes + listOfNotNull(parsed.equipmentNote)
        return WODMovement(
            name = parsed.name,
            reps = parsed.reps,
            repScheme = parsed.repScheme,
            distanceMeters = parsed.distanceMeters,
            calories = parsed.calories,
            weightMaleKg = parsed.weightMaleKg,
            weightFemaleKg = parsed.weightFemaleKg,
            scaleAlternative = scaleAlternative,
            notes = if (allNotes.isEmpty()) null else allNotes.joinToString(" · ")
        )
    }

    private fun firstInt(text: String): Int? {
        val digits = StringBuilder()
        for (ch in text) {
            if (ch.isDigit()) digits.append(ch)
            else if (digits.isNotEmpty()) break
        }
        return digits.toString().toIntOrNull()
    }

    private fun norm(s: String): String = CrossFitGlossary.normalize(s)

    /** Apple (live main) BoardScanLiteParser.catalogIndex: nombres oficiales
     * primero, fichas custom solo si la clave está libre, y alias publicados
     * sin pisar nombres canónicos (un alias sí puede desplazar a un custom). */
    private fun catalogIndex(catalog: List<CatalogExercise>): Map<String, CatalogExercise> {
        val index = mutableMapOf<String, CatalogExercise>()
        for (ex in catalog) if (!ex.isCustom && !ex.isCatalogArchived) index[norm(ex.name)] = ex
        for (ex in catalog) if (ex.isCustom && !ex.isCatalogArchived) index.putIfAbsent(norm(ex.name), ex)
        for (ex in catalog) {
            if (ex.isCustom || ex.isCatalogArchived) continue
            for (alias in ex.searchAliases) {
                val key = norm(alias)
                if (key.isEmpty()) continue
                val current = index[key]
                if (current == null || current.isCustom) index[key] = ex
            }
        }
        return index
    }
}
